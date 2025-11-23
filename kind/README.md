# KIND Deployment - Kubernetes Manifests

This directory contains the essential Kubernetes manifests for deploying ownCloud on KIND (Kubernetes IN Docker).

## Manifests

The following manifests will be applied by ArgoCD or kubectl:

1. **owncloud-namespace.yaml** - Creates the owncloud-namespace
2. **owncloud-secret.yaml** - Database and admin credentials
3. **configmap.yaml** - ownCloud configuration
4. **storageclass.yaml** - KIND-compatible storage class (local-path provisioner)
5. **postgresql.yaml** - PostgreSQL database deployment
6. **redis.yaml** - Redis cache deployment
7. **owncloud.yaml** - ownCloud application deployment

## Deployment with ArgoCD

To deploy using ArgoCD:

```bash
# Apply the ArgoCD Application manifest (located in docs-and-tools/)
kubectl apply -f docs-and-tools/argocd-application-kind.yaml -n argocd
```

ArgoCD will automatically sync and deploy all manifests in this directory.

## Manual Deployment

Alternatively, deploy manually with kubectl:

```bash
kubectl apply -f .
```

## Documentation and Tools

For complete documentation, deployment scripts, and alternative configurations, see the **docs-and-tools/** subdirectory.

## Access ownCloud

After deployment, port-forward to access ownCloud:

```bash
kubectl port-forward -n owncloud-namespace svc/owncloud 8080:8080
```

Then open: http://localhost:8080
