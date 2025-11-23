# KIND Documentation and Tools

This folder contains documentation, scripts, and alternative configurations that are not directly used by ArgoCD for deployment.

## Contents

### Documentation
- **README-original.md** - Complete documentation for KIND deployment, including setup instructions, deployment options, and troubleshooting

### ArgoCD Configuration
- **argocd-application-kind.yaml** - ArgoCD Application manifest for KIND deployment
  - This file should be applied separately to ArgoCD (not part of the main deployment)
  - Apply with: `kubectl apply -f argocd-application-kind.yaml -n argocd`

### Scripts
- **scripts/deploy-kind.sh** - Automated deployment script for KIND
- **scripts/diagnose-pvc.sh** - PVC troubleshooting script
- **scripts/fix-pvc.sh** - PVC fix script

### Alternative Configurations
- **owncloud-kind.yaml** - Alternative ownCloud configuration
- **storageclass-kind.yaml** - Alternative storage class configuration

## ArgoCD Deployment

The parent `kind/` directory contains only the essential Kubernetes manifests that ArgoCD needs to deploy the solution:
- `owncloud-namespace.yaml`
- `owncloud-secret.yaml`
- `configmap.yaml`
- `storageclass.yaml`
- `postgresql.yaml`
- `redis.yaml`
- `owncloud.yaml`

ArgoCD will automatically discover and apply these manifests when syncing from the repository.
