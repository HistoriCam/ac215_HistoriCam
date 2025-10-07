# Deployment

Infrastructure as Code and Kubernetes manifests for deploying HistoriCam to GCP.

## Structure

- `kubernetes/` - K8s manifests for GKE deployment
- `terraform/` - Terraform configs for GCP infrastructure

## Usage

```bash
# Deploy to GKE
kubectl apply -f kubernetes/

# Provision infrastructure
cd terraform
terraform init
terraform apply
```
