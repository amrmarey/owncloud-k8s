# Production Deployment

This directory contains Kubernetes manifests for **production** deployment of ownCloud.

## Files

- `owncloud-namespace.yaml` - Namespace configuration
- `owncloud-secret.yaml` - Secrets for database credentials
- `configmap.yaml` - ConfigMap for ownCloud configuration
- `storageclass.yaml` - StorageClass for persistent volumes
- `postgresql.yaml` - PostgreSQL database deployment
- `redis.yaml` - Redis cache deployment
- `owncloud.yaml` - ownCloud application deployment
- `owncloud-ingress.yaml` - Ingress configuration for external access
- `argocd-application.yaml` - ArgoCD Application manifest for GitOps deployment

## Deployment

### Manual Deployment

Deploy all resources in order:

```bash
kubectl apply -f owncloud-namespace.yaml
kubectl apply -f owncloud-secret.yaml
kubectl apply -f configmap.yaml
kubectl apply -f storageclass.yaml
kubectl apply -f postgresql.yaml
kubectl apply -f redis.yaml
kubectl apply -f owncloud.yaml
kubectl apply -f owncloud-ingress.yaml
```

Or deploy all at once:

```bash
kubectl apply -f production/
```

### ArgoCD Deployment

If using ArgoCD for GitOps:

```bash
# Install ArgoCD using the deployment script
./production/scripts/deploy-argocd.sh

# Then apply the application manifest
kubectl apply -f argocd-application.yaml
```

## Prerequisites

- Kubernetes cluster (v1.24+)
- kubectl configured to access your cluster
- Ingress controller (e.g., nginx-ingress) for external access
- StorageClass provisioner configured in your cluster

## Configuration

Before deploying, review and update:

1. **Secrets** (`owncloud-secret.yaml`) - Update database credentials
2. **Ingress** (`owncloud-ingress.yaml`) - Update hostname/domain
3. **Storage** (`storageclass.yaml`) - Ensure it matches your cluster's storage provisioner
4. **Resources** - Adjust CPU/memory limits based on your cluster capacity

## Verification

Check deployment status:

```bash
kubectl get pods -n owncloud
kubectl get svc -n owncloud
kubectl get pvc -n owncloud
kubectl get ingress -n owncloud
```

## Access

Once deployed, access ownCloud at the configured ingress hostname.
