# KIND (Local Development) Deployment

This directory contains Kubernetes manifests specifically for **KIND (Kubernetes IN Docker)** deployment for local development and testing.

## Files

- `owncloud-namespace.yaml` - Namespace definition
- `owncloud-secret.yaml` - Secrets for database and admin credentials
- `configmap.yaml` - ownCloud configuration
- `storageclass.yaml` - KIND-compatible storage class (uses local-path provisioner)
- `storageclass-kind.yaml` - Alternative storage class configuration
- `postgresql.yaml` - PostgreSQL database
- `redis.yaml` - Redis cache
- `owncloud.yaml` - ownCloud application (1 replica, ReadWriteOnce storage)
- `owncloud-kind.yaml` - Alternative ownCloud configuration for KIND
- `argocd-application-kind.yaml` - ArgoCD Application manifest for KIND deployment

## Quick Start

### Prerequisites

1. Install KIND:
   ```bash
   # See https://kind.sigs.k8s.io/docs/user/quick-start/#installation
   ```

2. Create a KIND cluster:
   ```bash
   kind create cluster --name owncloud
   ```

### Deployment Options

#### Option 1: Using Deployment Script (Recommended)

```bash
./kind/scripts/deploy-kind.sh
```

#### Option 2: With ArgoCD

```bash
# Install ArgoCD first, then apply the application
kubectl apply -f argocd-application-kind.yaml
```

#### Option 3: Manual Deployment

```bash
# Deploy all manifests in order
kubectl apply -f owncloud-namespace.yaml
kubectl apply -f owncloud-secret.yaml
kubectl apply -f configmap.yaml
kubectl apply -f storageclass.yaml
kubectl apply -f postgresql.yaml
kubectl apply -f redis.yaml
kubectl apply -f owncloud.yaml
```

Or deploy all at once:

```bash
kubectl apply -f kind/
```

## Verification

Check deployment status:

```bash
kubectl get pods -n owncloud
kubectl get svc -n owncloud
kubectl get pvc -n owncloud
```

## Access

Port-forward to access ownCloud locally:

```bash
kubectl port-forward -n owncloud svc/owncloud 8080:8080
```

Then access at: http://localhost:8080

## Important Notes

- **ReadWriteOnce storage** - KIND compatible, single node only
- **Single replica** - Suitable for local testing only
- **Local-path provisioner** - Uses hostPath storage on the KIND node
- **Not for production** - For production deployment, use the `../production/` folder

## Troubleshooting

If PVCs are not binding:

```bash
# Check if local-path provisioner is installed
kubectl get pods -n local-path-storage

# If not, install it
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

For more troubleshooting, see the root directory documentation files.
