# Project Folder Structure

This document describes the reorganized folder structure for easy deployment of ownCloud on Kubernetes.

## Overview

The project is now organized into dedicated folders for different deployment environments:

- **`kind/`** - Local development using KIND (Kubernetes IN Docker)
- **`production/`** - Production deployment configurations
- **Root directory** - Documentation and general resources

## Detailed Structure

```
owncloud-k8s/
│
├── kind/                                    # KIND (Local Development)
│   ├── README.md                            # KIND deployment guide
│   ├── scripts/                             # KIND-specific scripts
│   │   ├── deploy-kind.ps1                  # PowerShell deployment script
│   │   ├── deploy-kind.sh                   # Bash deployment script
│   │   ├── diagnose-pvc.sh                  # PVC diagnostics
│   │   └── fix-pvc.sh                       # PVC fix utility
│   ├── owncloud-namespace.yaml              # Namespace definition
│   ├── owncloud-secret.yaml                 # Secrets (credentials)
│   ├── configmap.yaml                       # ownCloud configuration
│   ├── storageclass.yaml                    # Local-path storage class
│   ├── storageclass-kind.yaml               # Alternative storage class
│   ├── postgresql.yaml                      # PostgreSQL database
│   ├── redis.yaml                           # Redis cache
│   ├── owncloud.yaml                        # ownCloud app (1 replica)
│   ├── owncloud-kind.yaml                   # Alternative ownCloud config
│   └── argocd-application-kind.yaml         # ArgoCD application manifest
│
├── production/                              # Production Deployment
│   ├── README.md                            # Production deployment guide
│   ├── scripts/                             # Production-specific scripts
│   │   ├── deploy-argocd.ps1                # ArgoCD setup (PowerShell)
│   │   └── deploy-argocd.sh                 # ArgoCD setup (Bash)
│   ├── owncloud-namespace.yaml              # Namespace definition
│   ├── owncloud-secret.yaml                 # Secrets (credentials)
│   ├── configmap.yaml                       # ownCloud configuration
│   ├── storageclass.yaml                    # Production storage class
│   ├── postgresql.yaml                      # PostgreSQL database
│   ├── redis.yaml                           # Redis cache
│   ├── owncloud.yaml                        # ownCloud app (2 replicas, HA)
│   ├── owncloud-ingress.yaml                # Ingress for external access
│   └── argocd-application.yaml              # ArgoCD application manifest
│
├── Documentation/                           # Documentation Files
│   ├── README.md                            # Main project README
│   ├── FOLDER-STRUCTURE.md                  # This file
│   ├── SCALING-NOTES.md                     # Scaling best practices
│   ├── STORAGE_MANAGEMENT.md                # Storage expansion guide
│   ├── TROUBLESHOOT-PVC.md                  # PVC troubleshooting
│   ├── KIND-ARGOCD-GUIDE.md                 # ArgoCD with KIND
│   ├── DEPLOYMENT-CHECKLIST.md              # Pre-deployment checklist
│   ├── ARGOCD-DEPLOY.md                     # ArgoCD deployment guide
│   ├── ARGOCD-FIX.md                        # ArgoCD troubleshooting
│   ├── FIX-PVC-BINDING.md                   # PVC binding fixes
│   ├── KIND-QUICKFIX.md                     # Quick KIND fixes
│   ├── QUICK-START.md                       # Quick start guide
│   ├── SCRIPTS-GUIDE.md                     # Scripts usage guide
│   └── FINAL-REVIEW.md                      # Final review checklist
│
└── Other Files
    ├── .git/                                # Git repository
    └── mariadb.yaml.backup                  # Legacy MariaDB config (backup)
```

## Key Differences: KIND vs Production

### KIND (Local Development)

**Purpose**: Local testing and development

**Characteristics**:
- Single replica deployment
- ReadWriteOnce storage (local-path provisioner)
- No ingress (use port-forward)
- Minimal resource requirements
- Quick setup and teardown

**Access**: `kubectl port-forward -n owncloud svc/owncloud 8080:8080`

### Production

**Purpose**: Production-ready deployment

**Characteristics**:
- 2-replica deployment (high availability)
- ReadWriteMany storage (NFS, CephFS, or cloud storage)
- Ingress for external access
- Pod anti-affinity rules
- PodDisruptionBudget
- Resource limits and requests
- Liveness and readiness probes

**Access**: Via configured ingress hostname

## Quick Deployment

### KIND Deployment

```bash
# From project root
cd kind
kubectl apply -f .

# Or use the deployment script
./kind/scripts/deploy-kind.sh
```

### Production Deployment

```bash
# From project root
cd production

# Review and update configurations first!
# - Update secrets in owncloud-secret.yaml
# - Update ingress hostname in owncloud-ingress.yaml
# - Verify storage class

kubectl apply -f .
```

## Scripts Location

All deployment scripts are now organized within their respective environment folders:

- **KIND scripts**: `kind/scripts/`
- **Production scripts**: `production/scripts/`

This organization makes it clear which scripts are for which environment and keeps everything related to an environment in one place.

## Migration from Old Structure

If you were using the old structure with files in the root directory:

1. **KIND deployments**: Use files in `kind/` folder
2. **Production deployments**: Use files in `production/` folder
3. **Scripts**: Now in `kind/scripts/` or `production/scripts/`
4. **Documentation**: Remains in root directory

The old script files in the root directory are kept for backward compatibility but should be considered deprecated. Use the scripts in the subfolders instead.

## Benefits of New Structure

✅ **Clear separation** between KIND and production configurations  
✅ **Easy to navigate** - everything for an environment is in one folder  
✅ **Prevents mistakes** - harder to accidentally deploy KIND config to production  
✅ **Better organization** - scripts are grouped with their related manifests  
✅ **Scalable** - easy to add new environments (e.g., staging, dev)  
✅ **Self-documenting** - folder names clearly indicate purpose  

## Next Steps

1. Review the README in your target environment folder (`kind/` or `production/`)
2. Update configuration files as needed (especially secrets and ingress)
3. Run the deployment using the appropriate script or kubectl commands
4. Refer to the documentation files in the root directory for troubleshooting and best practices
