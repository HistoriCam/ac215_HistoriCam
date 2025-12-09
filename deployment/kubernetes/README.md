# HistoriCam Kubernetes Deployment

Pulumi program spins up a GKE cluster, deploys vision + llm + chromadb, auto-loads Chroma, and fronts with nginx ingress + cert-manager TLS.

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

## Run
```bash
cd deployment/kubernetes
pulumi stack init dev    # or select dev
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

## Notes
- IngressHost must be set (use `EXTERNAL-IP>.sslip.io`). TLS via cert-manager/Let’s Encrypt HTTP01.
- Loader populates only `recursive-split-collection`; pass `chunk_type="recursive-split"` to llm/chat or change the API default if desired.
- If stuck on resources, ensure you’re on the correct cluster (`gcloud container clusters list`); old clusters consume quota. Delete stale clusters with `gcloud container clusters delete ...`.
