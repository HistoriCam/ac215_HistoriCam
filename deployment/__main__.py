import json
from textwrap import dedent

import pulumi
import pulumi_gcp as gcp

config = pulumi.Config()

# Core configuration
project = gcp.config.project or "ac215-historicam"
region = gcp.config.region or config.get("region") or "us-central1"
zone = config.get("zone") or f"{region}-a"

# Images to deploy (push these to Artifact Registry first)
vision_image = config.require("visionImage")
llm_image = config.require("llmImage")

# Vision service env
embeddings_path = config.require("visionEmbeddingsPath")
vision_top_k = config.get_int("visionTopK") or 5
vision_confidence = config.get_float("visionConfidence") or 0.7
vision_backup = config.get_float("visionBackup") or 0.4
embedding_dimension = config.get_int("visionEmbeddingDimension") or 512

# LLM service env
llm_extra_env = config.get("llmExtraEnv") or "{}"  # JSON string of extra envs if needed

# Hostname for TLS (use <IP>.sslip.io if you do not own a domain yet)
hostname = config.get("hostname") or ""
# Certificate hostname (must match the cert saved in /etc/letsencrypt/live/<name>/)
cert_hostname = config.get("certHostname") or hostname
# Email for Let's Encrypt registration (required for automatic cert issuance)
cert_email = config.get("certEmail")

# Service account that will run the VM (needs Vertex AI + Storage Viewer + Artifact Registry Reader)
instance_sa = config.get(
    "instanceServiceAccountEmail"
) or f"gcp-service@{project}.iam.gserviceaccount.com"

# SSH source ranges (default to IAP range; set via `pulumi config set sshSourceRanges "<ip>/32"`)
ssh_source_ranges = config.get("sshSourceRanges") or "35.235.240.0/20"

# Create a simple VPC with auto subnets (default network doesn't exist in this project)
network = gcp.compute.Network(
    "historicam-network",
    auto_create_subnetworks=True,
)

# Reserve a static external IP so your sslip.io hostname stays stable
address = gcp.compute.Address(
    "historicam-ip",
    address_type="EXTERNAL",
    region=region,
)

network_tags = ["historicam-app"]

# Allow HTTP/HTTPS to reach nginx (internal app ports stay closed)
firewall = gcp.compute.Firewall(
    "historicam-allow-web",
    network=network.id,
    allows=[
        gcp.compute.FirewallAllowArgs(protocol="tcp", ports=["80", "443"]),
    ],
    direction="INGRESS",
    source_ranges=["0.0.0.0/0"],
    target_tags=network_tags,
)

ssh_firewall = gcp.compute.Firewall(
    "historicam-allow-ssh",
    network=network.id,
    allows=[gcp.compute.FirewallAllowArgs(protocol="tcp", ports=["22"])],
    direction="INGRESS",
    source_ranges=[ssh_source_ranges],
    target_tags=network_tags,
)


def startup_script() -> str:
    llm_env_map = json.loads(llm_extra_env)
    llm_env_lines = " ".join(
        [f"-e {k}='{v}'" for k, v in llm_env_map.items()]
    )

    if not cert_hostname:
        raise ValueError(
            "certHostname is required (set via Pulumi config 'certHostname' or 'hostname'). "
            "For sslip.io, use <IP>.sslip.io after the VM IP is known."
        )
    if not cert_email:
        raise ValueError("certEmail is required for automatic Let's Encrypt issuance.")

    nginx_conf = dedent(
        f"""
        # HTTP redirect to HTTPS
        server {{
            listen 80;
            server_name {hostname or cert_hostname};
            return 301 https://$host$request_uri;
        }}

        # HTTPS proxy
        server {{
            listen 443 ssl;
            server_name {hostname or cert_hostname};

            ssl_certificate     /etc/letsencrypt/live/{cert_hostname}/fullchain.pem;
            ssl_certificate_key /etc/letsencrypt/live/{cert_hostname}/privkey.pem;
            ssl_session_cache   shared:SSL:10m;
            ssl_session_timeout 10m;

            # Vision API
            location /vision/ {{
                proxy_pass http://vision:8080/;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }}

            # LLM API
            location /llm/ {{
                proxy_pass http://llm:8000/;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }}

            # Chroma (optional/debug)
            location /chroma/ {{
                proxy_pass http://chromadb:8000/;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }}
        }}
        """
    ).strip()

    script = f"""#!/bin/bash
set -euo pipefail

apt-get update
apt-get install -y docker.io certbot python3-certbot-nginx
systemctl enable docker
systemctl start docker

gcloud auth configure-docker {region}-docker.pkg.dev -q || true

mkdir -p /opt/historicam
cat <<'EOF' > /opt/historicam/nginx.conf
{nginx_conf}
EOF

# Ensure host nginx is not holding port 80 (it may be installed as a certbot dependency)
systemctl stop nginx || true
systemctl disable nginx || true

# Obtain/renew certificate; if it fails, continue and serve HTTP-only
certbot certonly --standalone --non-interactive --agree-tos \\
  -m {cert_email} \\
  -d {cert_hostname} \\
  --keep-until-expiring || echo "Certbot failed; continuing without TLS"

docker network create historicam-net || true

# ChromaDB
docker run -d --restart always --name chromadb --network historicam-net \\
  -p 8002:8000 \\
  -e IS_PERSISTENT=TRUE \\
  -e ANONYMIZED_TELEMETRY=FALSE \\
  chromadb/chroma:latest

# Vision service
docker run -d --restart always --name vision --network historicam-net \\
  -p 8080:8080 \\
  -e GCP_PROJECT='{project}' \\
  -e GCP_LOCATION='{region}' \\
  -e EMBEDDINGS_PATH='{embeddings_path}' \\
  -e EMBEDDING_DIMENSION='{embedding_dimension}' \\
  -e TOP_K='{vision_top_k}' \\
  -e CONFIDENCE_THRESHOLD='{vision_confidence}' \\
  -e BACKUP_THRESHOLD='{vision_backup}' \\
  {vision_image}

# LLM service
docker run -d --restart always --name llm --network historicam-net \\
  -p 8001:8000 \\
  -e GCP_PROJECT='{project}' \\
  -e GCP_LOCATION='{region}' \\
  -e CHROMADB_HOST='chromadb' \\
  -e CHROMADB_PORT='8000' \\
  {llm_env_lines} \\
  {llm_image} \\
  /bin/bash -c "cd /app && /.venv/bin/uvicorn server:app --host 0.0.0.0 --port 8000"

# Nginx proxy
docker run -d --restart always --name nginx --network historicam-net \\
  -p 80:80 -p 443:443 \\
  -v /opt/historicam/nginx.conf:/etc/nginx/conf.d/default.conf:ro \\
  -v /etc/letsencrypt:/etc/letsencrypt \\
  nginx:stable

echo "Deployment complete. If using sslip.io, run certbot manually:"
echo "  certbot --nginx -d {hostname or '<IP>.sslip.io'} --non-interactive --agree-tos -m you@example.com"
"""
    return script


instance = gcp.compute.Instance(
    "historicam-vm",
    machine_type="e2-standard-2",
    zone=zone,
    boot_disk=gcp.compute.InstanceBootDiskArgs(
        initialize_params=gcp.compute.InstanceBootDiskInitializeParamsArgs(
            image="ubuntu-os-cloud/ubuntu-2204-lts",
            size=30,
        )
    ),
    network_interfaces=[
        gcp.compute.InstanceNetworkInterfaceArgs(
            network=network.id,
            access_configs=[
                gcp.compute.InstanceNetworkInterfaceAccessConfigArgs(
                    nat_ip=address.address,
                )
            ],
        )
    ],
    metadata={"startup-script": startup_script()},
    tags=network_tags,
    service_account=gcp.compute.InstanceServiceAccountArgs(
        email=instance_sa,
        scopes=["https://www.googleapis.com/auth/cloud-platform"],
    ),
    opts=pulumi.ResourceOptions(depends_on=[firewall], delete_before_replace=True),
)

pulumi.export("ip_address", address.address)
pulumi.export("vision_url", pulumi.Output.concat("https://", hostname or address.address.apply(lambda ip: f"{ip}.sslip.io"), "/vision"))
pulumi.export("llm_url", pulumi.Output.concat("https://", hostname or address.address.apply(lambda ip: f"{ip}.sslip.io"), "/llm"))
