# HistoriCam Kubernetes Deployment

Pulumi program spins up a GKE cluster, deploys vision + llm + chromadb, auto-loads Chroma, and fronts with nginx ingress + cert-manager TLS.

## Backend & stack (shared)
- State backend: `gs://ac215-historicam-pulumi-state-bucket`
- Everyone must log in to this backend and use the same stack name (`dev`) to avoid creating extra clusters.
  ```bash
  pulumi logout || true
  pulumi login gs://ac215-historicam-pulumi-state-bucket
  pulumi stack select dev   # do NOT run stack init unless you truly want a new stack
  pulumi whoami --verbose   # verify backend is the GCS bucket
  pulumi stack ls           # should show dev
  ```

## Config (Pulumi stack)
- `gcp:project`: ac215-historicam
- `gcp:region`: us-central1
- `visionImage`: us-central1-docker.pkg.dev/ac215-historicam/historicam/vision:latest
- `llmImage`: us-central1-docker.pkg.dev/ac215-historicam/historicam/llm:latest
- `visionEmbeddingsPath`: gs://historicam-images/embeddings/.../embeddings.jsonl
- `ingressHost`: <LB_IP>.sslip.io (from ingress-nginx-controller EXTERNAL-IP)
- `certEmail`: hughvandeventer@g.harvard.edu
- Optional: nodeCount/minNodes/maxNodes/machineType

## What Pulumi creates
- VPC/subnet, GKE cluster (us-central1-a) + nodepool (e2-standard-2 by default, pd-standard disks)
- Namespace `dev`
- Helm: ingress-nginx (admission disabled)
- Helm: cert-manager (CRDs, v1.14.4) + ClusterIssuer `letsencrypt-http` (HTTP01 via nginx)
- Deployments/Services:
  - chromadb (svc name `chromadb`, port 8000)
  - vision (port 8080; envs for GCP project/location, embeddings, thresholds)
  - llm (port 8000; envs GCP project/location, CHROMADB_HOST=chromadb, CHROMADB_PORT=8000)
- Loader Job `chroma-loader`: waits for chroma DNS + HTTP, runs `python cli.py --chunk --embed --load --chunk_type recursive-split` inside llm image.
- Ingress `app-ingress`: regex paths `/vision(/|$)(.*)` → vision, `/llm(/|$)(.*)` → llm; TLS via cert-manager, secret `app-tls`, annotations for nginx + issuer.

## Run (setup + deploy)
```bash
cd deployment/kubernetes
pulumi login gs://ac215-historicam-pulumi-state-bucket
pulumi stack select dev
pulumi config set gcp:project ac215-historicam
pulumi config set gcp:region us-central1
pulumi config set visionImage us-central1-docker.pkg.dev/ac215-historicam/historicam/vision:latest
pulumi config set llmImage us-central1-docker.pkg.dev/ac215-historicam/historicam/llm:latest
pulumi config set visionEmbeddingsPath gs://historicam-images/embeddings/.../embeddings.jsonl
pulumi config set ingressHost <LB_IP>.sslip.io
pulumi config set certEmail hughvandeventer@g.harvard.edu
export PULUMI_PYTHON_CMD=/home/app/.venv/bin/python
pulumi up
```

## Check
```bash
pulumi stack output kubeconfig --show-secrets > /tmp/kubeconfig.yaml
export KUBECONFIG=/tmp/kubeconfig.yaml
kubectl get deploy,svc,jobs,pods -n dev
kubectl get ingress app-ingress -n dev -o wide
kubectl logs job/chroma-loader -n dev
curl -I https://<ingressHost>/vision/
curl -X POST https://<ingressHost>/llm/chat -H "Content-Type: application/json" -d '{"question":"Hi","chunk_type":"recursive-split"}'
```


## Maintenance
- Always use the shared backend + `dev` stack to avoid accidental new clusters. If you see extra clusters, delete with `gcloud container clusters delete <name> --zone us-central1-a --project ac215-historicam` after confirming they are not in use.
- If ingress IP changes (after recreating ingress/cluster), update `ingressHost` to `<new_LB_IP>.sslip.io` and rerun `pulumi up`.
- To inspect the live cluster without Pulumi: `gcloud container clusters get-credentials historicam-cluster-779d834 --zone us-central1-a --project ac215-historicam`.
- Loader job only seeds `recursive-split-collection`; include `chunk_type="recursive-split"` in llm/chat calls unless you change the API default.
