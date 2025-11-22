# KIND Deployment Files

This directory contains Kubernetes manifests specifically for KIND (Kubernetes IN Docker) deployment.

## Files

- `owncloud-namespace.yaml` - Namespace definition
- `storageclass.yaml` - KIND-compatible storage class (uses local-path provisioner)
- `owncloud-secret.yaml` - Secrets for database and admin credentials
- `configmap.yaml` - ownCloud configuration
- `postgresql.yaml` - PostgreSQL database
- `redis.yaml` - Redis cache
- `owncloud.yaml` - ownCloud application (1 replica, ReadWriteOnce storage)

## Usage

### With ArgoCD

```bash
# Apply the ArgoCD application
kubectl apply -f ../argocd-application-kind.yaml
```

### Manual Deployment

```bash
# Deploy all manifests
kubectl apply -f .
```

## Notes

- Uses ReadWriteOnce storage (KIND compatible)
- Single replica deployment
- Suitable for local testing only
- For production, use the files in the parent directory
