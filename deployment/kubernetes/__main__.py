import base64
import pulumi
import pulumi_gcp as gcp
import pulumi_kubernetes as k8s

config = pulumi.Config()
project = gcp.config.project or config.require("gcp:project")
region = gcp.config.region or config.get("region") or "us-central1"
zone = config.get("zone") or f"{region}-a"

# Images and app config
vision_image = config.require("visionImage")  # e.g., us-central1-docker.pkg.dev/ac215-historicam/historicam/vision:latest
llm_image = config.require("llmImage")        # e.g., us-central1-docker.pkg.dev/ac215-historicam/historicam/llm:latest
embeddings_path = config.require("visionEmbeddingsPath")
ingress_host = config.get("ingressHost") or ""  # e.g., <STATIC_IP>.sslip.io
cert_email = config.get("certEmail") or ""      # for cert-manager if added later
if not ingress_host:
    raise ValueError("ingressHost is required (e.g., <STATIC_IP>.sslip.io)")
if not cert_email:
    raise ValueError("certEmail is required for Let's Encrypt issuance")

# Cluster sizing
node_count = config.get_int("nodeCount") or 2
min_nodes = config.get_int("minNodes") or 2
max_nodes = config.get_int("maxNodes") or 4
node_machine_type = config.get("nodeMachineType") or "e2-standard-2"

# Create a custom VPC and subnetwork since default does not exist
vpc = gcp.compute.Network("historicam-k8s-network", auto_create_subnetworks=False)
subnet = gcp.compute.Subnetwork(
    "historicam-k8s-subnet",
    ip_cidr_range="10.10.0.0/16",
    region=region,
    network=vpc.id,
)

# Create GKE cluster using the custom network/subnet
cluster = gcp.container.Cluster(
    "historicam-cluster",
    location=zone,
    initial_node_count=1,
    remove_default_node_pool=True,
    node_config=gcp.container.ClusterNodeConfigArgs(
        machine_type=node_machine_type,
        oauth_scopes=["https://www.googleapis.com/auth/cloud-platform"],
    ),
    resource_labels={"env": "dev"},
    network=vpc.id,
    subnetwork=subnet.name,
    deletion_protection=False,
)

# Managed node pool with autoscaling
node_pool = gcp.container.NodePool(
    "historicam-nodepool",
    cluster=cluster.name,
    location=zone,
    initial_node_count=node_count,
    autoscaling=gcp.container.NodePoolAutoscalingArgs(
        min_node_count=min_nodes,
        max_node_count=max_nodes,
        location_policy="BALANCED",
    ),
    node_config=gcp.container.NodePoolNodeConfigArgs(
        machine_type=node_machine_type,
        oauth_scopes=["https://www.googleapis.com/auth/cloud-platform"],
        disk_size_gb=50,
        disk_type="pd-standard",
    ),
)

# Build kubeconfig
def generate_kubeconfig(args):
    endpoint, ca = args
    return f"""
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: {ca}
    server: https://{endpoint}
  name: gke
contexts:
- context:
    cluster: gke
    user: gke
  name: gke
current-context: gke
users:
- name: gke
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: gke-gcloud-auth-plugin
      installHint: Install gke-gcloud-auth-plugin for GKE auth.
      provideClusterInfo: true
"""

kubeconfig = pulumi.Output.all(cluster.endpoint, cluster.master_auth.cluster_ca_certificate).apply(generate_kubeconfig)

k8s_provider = k8s.Provider(
    "historicam-k8s",
    kubeconfig=kubeconfig,
)

# Namespace
ns = k8s.core.v1.Namespace("dev-ns", metadata={"name": "dev"}, opts=pulumi.ResourceOptions(provider=k8s_provider))

# Cert-manager namespace and Helm chart (for Let's Encrypt)
cert_ns = k8s.core.v1.Namespace(
    "cert-manager-ns",
    metadata={"name": "cert-manager"},
    opts=pulumi.ResourceOptions(provider=k8s_provider),
)

cert_chart = k8s.helm.v3.Chart(
    "cert-manager",
    k8s.helm.v3.ChartOpts(
        chart="cert-manager",
        version="v1.14.4",
        fetch_opts=k8s.helm.v3.FetchOpts(repo="https://charts.jetstack.io"),
        namespace=cert_ns.metadata["name"],
        values={
            "installCRDs": True,
        },
    ),
    opts=pulumi.ResourceOptions(provider=k8s_provider),
)

# ClusterIssuer for Let's Encrypt (HTTP-01 via nginx ingress)
cluster_issuer = k8s.apiextensions.CustomResource(
    "letsencrypt-http",
    api_version="cert-manager.io/v1",
    kind="ClusterIssuer",
    metadata={"name": "letsencrypt-http"},
    spec={
        "acme": {
            "email": cert_email,
            "server": "https://acme-v02.api.letsencrypt.org/directory",
            "privateKeySecretRef": {"name": "letsencrypt-http-private-key"},
            "solvers": [
                {
                    "http01": {
                        "ingress": {"ingressClassName": "nginx"}
                    }
                }
            ],
        }
    },
    opts=pulumi.ResourceOptions(provider=k8s_provider, depends_on=[cert_chart]),
)

# Install nginx-ingress via Helm (official chart)
ingress_chart = k8s.helm.v3.Chart(
    "ingress-nginx",
    k8s.helm.v3.ChartOpts(
        chart="ingress-nginx",
        version="4.10.0",
        fetch_opts=k8s.helm.v3.FetchOpts(repo="https://kubernetes.github.io/ingress-nginx"),
        namespace=ns.metadata["name"],
        values={
            "controller": {
                "publishService": {"enabled": True},
            },
            "admissionWebhooks": {
                "enabled": False,
            }
        },
    ),
    opts=pulumi.ResourceOptions(provider=k8s_provider),
)

# Services env
vision_env = [
    {"name": "GCP_PROJECT", "value": project},
    {"name": "GCP_LOCATION", "value": region},
    {"name": "EMBEDDINGS_PATH", "value": embeddings_path},
    {"name": "EMBEDDING_DIMENSION", "value": "512"},
    {"name": "TOP_K", "value": "5"},
    {"name": "CONFIDENCE_THRESHOLD", "value": "0.7"},
    {"name": "BACKUP_THRESHOLD", "value": "0.4"},
]

llm_env = [
    {"name": "GCP_PROJECT", "value": project},
    {"name": "GCP_LOCATION", "value": region},
    {"name": "CHROMADB_HOST", "value": "chromadb"},
    {"name": "CHROMADB_PORT", "value": "8000"},
]

# Chroma Deployment + Service
chroma_dep = k8s.apps.v1.Deployment(
    "chromadb",
    metadata={"namespace": ns.metadata["name"]},
    spec=k8s.apps.v1.DeploymentSpecArgs(
        replicas=1,
        selector={"matchLabels": {"app": "chromadb"}},
        template=k8s.core.v1.PodTemplateSpecArgs(
            metadata={"labels": {"app": "chromadb"}},
            spec=k8s.core.v1.PodSpecArgs(
                containers=[
                    k8s.core.v1.ContainerArgs(
                        name="chromadb",
                        image="chromadb/chroma:latest",
                        ports=[k8s.core.v1.ContainerPortArgs(container_port=8000)],
                        env=[
                            {"name": "IS_PERSISTENT", "value": "TRUE"},
                            {"name": "ANONYMIZED_TELEMETRY", "value": "FALSE"},
                        ],
                    )
                ]
            ),
        ),
    ),
    opts=pulumi.ResourceOptions(provider=k8s_provider),
)

chroma_svc = k8s.core.v1.Service(
    "chromadb-svc",
    metadata={
        "namespace": ns.metadata["name"],
        "name": "chromadb",
        "labels": {"app": "chromadb"},
    },
    spec=k8s.core.v1.ServiceSpecArgs(
        selector={"app": "chromadb"},
        ports=[k8s.core.v1.ServicePortArgs(port=8000, target_port=8000)],
    ),
    opts=pulumi.ResourceOptions(provider=k8s_provider),
)

# Vision Deployment + Service
vision_dep = k8s.apps.v1.Deployment(
    "vision",
    metadata={"namespace": ns.metadata["name"]},
    spec=k8s.apps.v1.DeploymentSpecArgs(
        replicas=1,
        selector={"matchLabels": {"app": "vision"}},
        template=k8s.core.v1.PodTemplateSpecArgs(
            metadata={"labels": {"app": "vision"}},
            spec=k8s.core.v1.PodSpecArgs(
                containers=[
                    k8s.core.v1.ContainerArgs(
                        name="vision",
                        image=vision_image,
                        ports=[k8s.core.v1.ContainerPortArgs(container_port=8080)],
                        env=[k8s.core.v1.EnvVarArgs(name=e["name"], value=e["value"]) for e in vision_env],
                        resources=k8s.core.v1.ResourceRequirementsArgs(
                            requests={"cpu": "250m", "memory": "512Mi"},
                            limits={"cpu": "500m", "memory": "1Gi"},
                        ),
                    )
                ]
            ),
        ),
    ),
    opts=pulumi.ResourceOptions(provider=k8s_provider),
)

vision_svc = k8s.core.v1.Service(
    "vision-svc",
    metadata={"namespace": ns.metadata["name"], "labels": {"app": "vision"}},
    spec=k8s.core.v1.ServiceSpecArgs(
        selector={"app": "vision"},
        ports=[k8s.core.v1.ServicePortArgs(port=8080, target_port=8080)],
    ),
    opts=pulumi.ResourceOptions(provider=k8s_provider),
)

# LLM Deployment + Service
llm_dep = k8s.apps.v1.Deployment(
    "llm",
    metadata={"namespace": ns.metadata["name"]},
    spec=k8s.apps.v1.DeploymentSpecArgs(
        replicas=1,
        selector={"matchLabels": {"app": "llm"}},
        template=k8s.core.v1.PodTemplateSpecArgs(
            metadata={"labels": {"app": "llm"}},
            spec=k8s.core.v1.PodSpecArgs(
                containers=[
                    k8s.core.v1.ContainerArgs(
                        name="llm",
                        image=llm_image,
                        ports=[k8s.core.v1.ContainerPortArgs(container_port=8000)],
                        env=[k8s.core.v1.EnvVarArgs(name=e["name"], value=e["value"]) for e in llm_env],
                        command=["/bin/bash", "-c"],
                        args=["cd /app && /.venv/bin/uvicorn server:app --host 0.0.0.0 --port 8000"],
                        resources=k8s.core.v1.ResourceRequirementsArgs(
                            requests={"cpu": "250m", "memory": "512Mi"},
                            limits={"cpu": "500m", "memory": "1Gi"},
                        ),
                    )
                ]
            ),
        ),
    ),
    opts=pulumi.ResourceOptions(provider=k8s_provider),
)

llm_svc = k8s.core.v1.Service(
    "llm-svc",
    metadata={"namespace": ns.metadata["name"], "labels": {"app": "llm"}},
    spec=k8s.core.v1.ServiceSpecArgs(
        selector={"app": "llm"},
        ports=[k8s.core.v1.ServicePortArgs(port=8000, target_port=8000)],
    ),
    opts=pulumi.ResourceOptions(provider=k8s_provider),
)

# Horizontal Pod Autoscalers (basic CPU-based autoscaling)
vision_hpa = k8s.autoscaling.v2.HorizontalPodAutoscaler(
    "vision-hpa",
    metadata={"namespace": ns.metadata["name"]},
    spec=k8s.autoscaling.v2.HorizontalPodAutoscalerSpecArgs(
        scale_target_ref=k8s.autoscaling.v2.CrossVersionObjectReferenceArgs(
            api_version="apps/v1",
            kind="Deployment",
            name=vision_dep.metadata["name"],
        ),
        min_replicas=1,
        max_replicas=4,
        metrics=[
            k8s.autoscaling.v2.MetricSpecArgs(
                type="Resource",
                resource=k8s.autoscaling.v2.ResourceMetricSourceArgs(
                    name="cpu",
                    target=k8s.autoscaling.v2.MetricTargetArgs(
                        type="Utilization",
                        average_utilization=80,
                    ),
                ),
            )
        ],
    ),
    opts=pulumi.ResourceOptions(provider=k8s_provider),
)

llm_hpa = k8s.autoscaling.v2.HorizontalPodAutoscaler(
    "llm-hpa",
    metadata={"namespace": ns.metadata["name"]},
    spec=k8s.autoscaling.v2.HorizontalPodAutoscalerSpecArgs(
        scale_target_ref=k8s.autoscaling.v2.CrossVersionObjectReferenceArgs(
            api_version="apps/v1",
            kind="Deployment",
            name=llm_dep.metadata["name"],
        ),
        min_replicas=1,
        max_replicas=4,
        metrics=[
            k8s.autoscaling.v2.MetricSpecArgs(
                type="Resource",
                resource=k8s.autoscaling.v2.ResourceMetricSourceArgs(
                    name="cpu",
                    target=k8s.autoscaling.v2.MetricTargetArgs(
                        type="Utilization",
                        average_utilization=80,
                    ),
                ),
            )
        ],
    ),
    opts=pulumi.ResourceOptions(provider=k8s_provider),
)

# Loader Job to pre-load Chroma
loader_job = k8s.batch.v1.Job(
    "chroma-loader",
    metadata={"namespace": ns.metadata["name"], "name": "chroma-loader"},
    spec=k8s.batch.v1.JobSpecArgs(
        backoff_limit=2,
        template=k8s.core.v1.PodTemplateSpecArgs(
            metadata={"labels": {"app": "chroma-loader"}},
            spec=k8s.core.v1.PodSpecArgs(
                restart_policy="Never",
                containers=[
                    k8s.core.v1.ContainerArgs(
                        name="loader",
                        image=llm_image,
                        env=[k8s.core.v1.EnvVarArgs(name=e["name"], value=e["value"]) for e in llm_env],
                        command=["/bin/bash", "-c"],
                        args=[
                            "set -euo pipefail; "
                            "export CHROMADB_HOST=chromadb.dev.svc.cluster.local; export CHROMADB_PORT=8000; "
                            "for i in $(seq 1 60); do "
                            "  getent hosts ${CHROMADB_HOST} >/dev/null 2>&1 && "
                            "  curl -s http://${CHROMADB_HOST}:${CHROMADB_PORT}/api/v1/collections >/dev/null 2>&1 && break; "
                            "  sleep 2; "
                            "done; "
                            "curl -s http://${CHROMADB_HOST}:${CHROMADB_PORT}/api/v1/collections >/dev/null 2>&1 || { echo 'Chroma unreachable'; exit 1; }; "
                            "source /.venv/bin/activate && python cli.py --chunk --embed --load --chunk_type recursive-split"
                        ],
                    )
                ],
            ),
        ),
    ),
    opts=pulumi.ResourceOptions(
        provider=k8s_provider,
        delete_before_replace=True,
        replace_on_changes=["spec.template"],
    ),
)

# Ingress via nginx-ingress (assumes controller installed; add cert-manager separately if you want HTTPS)
ingress_rules = []
if ingress_host:
    ingress_rules.append(
        k8s.networking.v1.IngressRuleArgs(
            host=ingress_host,
            http=k8s.networking.v1.HTTPIngressRuleValueArgs(
                paths=[
                    k8s.networking.v1.HTTPIngressPathArgs(
                        path="/vision(/|$)(.*)",
                        path_type="Prefix",
                        backend=k8s.networking.v1.IngressBackendArgs(
                            service=k8s.networking.v1.IngressServiceBackendArgs(
                                name=vision_svc.metadata["name"],
                                port=k8s.networking.v1.ServiceBackendPortArgs(number=8080),
                            )
                        ),
                    ),
                    k8s.networking.v1.HTTPIngressPathArgs(
                        path="/llm(/|$)(.*)",
                        path_type="Prefix",
                        backend=k8s.networking.v1.IngressBackendArgs(
                            service=k8s.networking.v1.IngressServiceBackendArgs(
                                name=llm_svc.metadata["name"],
                                port=k8s.networking.v1.ServiceBackendPortArgs(number=8000),
                            )
                        ),
                    ),
                ]
            ),
        )
    )
else:
    ingress_rules.append(
        k8s.networking.v1.IngressRuleArgs(
            http=k8s.networking.v1.HTTPIngressRuleValueArgs(
                paths=[
                    k8s.networking.v1.HTTPIngressPathArgs(
                        path="/vision(/|$)(.*)",
                        path_type="Prefix",
                        backend=k8s.networking.v1.IngressBackendArgs(
                            service=k8s.networking.v1.IngressServiceBackendArgs(
                                name=vision_svc.metadata["name"],
                                port=k8s.networking.v1.ServiceBackendPortArgs(number=8080),
                            )
                        ),
                    ),
                    k8s.networking.v1.HTTPIngressPathArgs(
                        path="/llm(/|$)(.*)",
                        path_type="Prefix",
                        backend=k8s.networking.v1.IngressBackendArgs(
                            service=k8s.networking.v1.IngressServiceBackendArgs(
                                name=llm_svc.metadata["name"],
                                port=k8s.networking.v1.ServiceBackendPortArgs(number=8000),
                            )
                        ),
                    ),
                ]
            )
        )
    )

ingress = k8s.networking.v1.Ingress(
    "app-ingress",
    metadata={
        "namespace": ns.metadata["name"],
        "annotations": {
            "kubernetes.io/ingress.class": "nginx",
            "cert-manager.io/cluster-issuer": "letsencrypt-http",
            "nginx.ingress.kubernetes.io/use-regex": "true",
            "nginx.ingress.kubernetes.io/rewrite-target": "/$2",
        },
    },
    spec=k8s.networking.v1.IngressSpecArgs(
        rules=ingress_rules,
        tls=[
            k8s.networking.v1.IngressTLSArgs(
                hosts=[ingress_host],
                secret_name="app-tls",
            )
        ],
    ),
    opts=pulumi.ResourceOptions(provider=k8s_provider, depends_on=[ingress_chart, cluster_issuer]),
)

pulumi.export("cluster_name", cluster.name)
pulumi.export("kubeconfig", kubeconfig)
pulumi.export("ingress_host", ingress_host or "(set ingressHost config to use a host)")
