# HistoriCam Deployment (Cloud VM + nginx + TLS)

This folder contains the Pulumi stack and helper container to deploy the vision and LLM services on a single GCE VM with nginx reverse proxy, TLS via Let’s Encrypt, and a Chroma sidecar.

## Prereqs
- Secrets in `secrets/` (gitignored):
  - `deployment.json` (deploy SA with Cloud Build/Artifact Registry/Compute perms)
  - `gcs-service-account.json` (vision service, optional if using VM SA)
  - `llm-service-account.json` (LLM service, if you prefer key-based creds)
- Docker installed locally.
- GCP APIs enabled: Cloud Build, Artifact Registry, Compute, IAM, Cloud Storage, Vertex AI.

## Quick flow (from repo root)
```bash
cd deployment
sh docker-shell.sh            # enters the deployment helper container
# inside the container:
pulumi stack select dev || pulumi stack init dev
pulumi config set gcp:project ac215-historicam
pulumi config set gcp:region us-central1
pulumi config set visionImage us-central1-docker.pkg.dev/ac215-historicam/historicam/vision:latest
pulumi config set llmImage us-central1-docker.pkg.dev/ac215-historicam/historicam/llm:latest
pulumi config set visionEmbeddingsPath gs://historicam-images/embeddings/v20251208_170256/multimodal-512d/embeddings.jsonl
pulumi config set certHostname 35.224.247.219.sslip.io      # set after IP known; replace with your hostname
pulumi config set certEmail you@example.com
# optional: pulumi config set instanceServiceAccountEmail <sa>@ac215-historicam.iam.gserviceaccount.com
# optional: pulumi config set llmExtraEnv '{"GOOGLE_APPLICATION_CREDENTIALS":"/secrets/llm-service-account.json"}'
export PULUMI_PYTHON_CMD=/home/app/.venv/bin/python
pulumi up --stack dev
```

## Build and push images (if changed)
```bash
PROJECT=ac215-historicam
REGION=us-central1
gcloud builds submit ../services/vision \
  --tag $REGION-docker.pkg.dev/$PROJECT/historicam/vision:latest \
  --region=$REGION \
  --gcs-source-staging-dir=gs://$PROJECT-build-artifacts/source \
  --gcs-log-dir=gs://$PROJECT-build-artifacts/logs

gcloud builds submit ../services/llm-rag \
  --tag $REGION-docker.pkg.dev/$PROJECT/historicam/llm:latest \
  --region=$REGION \
  --gcs-source-staging-dir=gs://$PROJECT-build-artifacts/source \
  --gcs-log-dir=gs://$PROJECT-build-artifacts/logs
```

## Redeploy/replace VM
Use replace so startup script (nginx + certbot + containers) reruns cleanly:
```bash
pulumi stack select dev
export PULUMI_PYTHON_CMD=/home/app/.venv/bin/python
pulumi up --stack dev --replace "urn:pulumi:dev::historicam-deploy::gcp:compute/instance:Instance::historicam-vm"
```

## Runtime details
- Services: `https://<certHostname>/vision`, `https://<certHostname>/llm`
- nginx proxies `/vision`, `/llm`, `/chroma`; TLS from Let’s Encrypt via startup script (certbot standalone, host nginx stopped).
- VM SA (or provided key) needs: `Vertex AI User`, `Storage Object Viewer`, `Artifact Registry Reader`. Grant to the VM SA or mount `llm-service-account.json` and set `GOOGLE_APPLICATION_CREDENTIALS`.
- If certbot ever fails, startup still launches containers (HTTP). Check `/var/log/cloud-init-output.log` on the VM.

## Secrets usage
- To use a key in the LLM container, ensure `secrets/llm-service-account.json` exists and set `llmExtraEnv` to include `GOOGLE_APPLICATION_CREDENTIALS=/secrets/llm-service-account.json`. The deployment helper mounts `secrets/` into the VM as `/secrets`.

## Testing
```bash
curl -I https://<certHostname>/vision/
curl -X POST https://<certHostname>/llm/chat \
  -H "Content-Type: application/json" \
  -d '{"question":"Hi"}'
```
