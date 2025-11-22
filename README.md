
# 🌥️ OwnCloud on Kubernetes

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.19+-blue.svg)](https://kubernetes.io/)
[![Helm 3](https://img.shields.io/badge/Helm-3.x-orange.svg)](https://helm.sh/)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Deploy an **OwnCloud** instance on a Kubernetes cluster using the provided manifests. This setup leverages **PostgreSQL** as a database backend, **Redis** for caching, and uses Kubernetes **Ingress** for managing external access.

## ⚠️ IMPORTANT DISCLAIMER

> **FOR EDUCATIONAL AND LEARNING PURPOSES ONLY**
>
> This project is provided as a learning resource and demonstration of Kubernetes deployment concepts. It is **NOT intended for production use** without proper security review, testing, and hardening.
>
> **Key Points:**
> - ✋ **No Warranty**: Provided "as is" without any guarantees
> - 🔒 **Security**: You are responsible for securing your deployment
> - 📚 **Educational**: Intended for learning and experimentation
> - ⚖️ **No Liability**: Author is not liable for any damages or issues
> - 🔐 **Change Defaults**: Always change default passwords and secrets
> - 📋 **Compliance**: Ensure compliance with applicable laws and licenses
>
> **By using this project, you acknowledge that you do so entirely at your own risk.**
>
> See the [LICENSE](LICENSE) file for complete terms and conditions.

## 🚀 Features

- **High Availability**: 2-pod deployment with automatic failover and load balancing
- **Scalable Deployment**: Deploy OwnCloud with Kubernetes to easily scale horizontally
- **Production Ready**: Includes resource limits, health checks, pod disruption budgets, and anti-affinity rules
- **Secure Storage**: Manages sensitive data using Kubernetes Secrets
- **Shared Storage**: ReadWriteMany access mode for multi-pod data access
- **Customizable Configuration**: Easily configure the setup with ConfigMaps
- **Optimized Performance**: Uses Redis for caching and session management
- **Best Practices**: Follows ownCloud's official Kubernetes deployment recommendations
- **Multi-Environment**: Separate configurations for KIND (local) and production deployments

## 📁 Project Structure

```
owncloud-k8s/
├── kind/                          # KIND (local development) deployment
│   ├── README.md                  # KIND-specific documentation
│   ├── scripts/                   # KIND deployment scripts
│   │   ├── deploy-kind.sh         # Automated deployment
│   │   ├── diagnose-pvc.sh        # PVC diagnostics
│   │   └── fix-pvc.sh             # PVC troubleshooting
│   ├── owncloud-namespace.yaml
│   ├── owncloud-secret.yaml
│   ├── configmap.yaml
│   ├── storageclass.yaml
│   ├── postgresql.yaml
│   ├── redis.yaml
│   ├── owncloud.yaml
│   └── argocd-application-kind.yaml
├── production/                    # Production deployment
│   ├── README.md                  # Production-specific documentation
│   ├── scripts/                   # Production deployment scripts
│   │   └── deploy-argocd.sh       # ArgoCD setup
│   ├── owncloud-namespace.yaml
│   ├── owncloud-secret.yaml
│   ├── configmap.yaml
│   ├── storageclass.yaml
│   ├── postgresql.yaml
│   ├── redis.yaml
│   ├── owncloud.yaml
│   ├── owncloud-ingress.yaml
│   └── argocd-application.yaml
├── docs/                          # Documentation
│   ├── FOLDER-STRUCTURE.md        # Project structure guide
│   ├── SCALING-NOTES.md           # Scaling best practices
│   ├── STORAGE_MANAGEMENT.md      # Storage expansion guide
│   ├── TROUBLESHOOT-PVC.md        # PVC troubleshooting
│   ├── KIND-ARGOCD-GUIDE.md       # ArgoCD with KIND
│   ├── DEPLOYMENT-CHECKLIST.md    # Pre-deployment checklist
│   └── ... (other documentation)
├── archive/                       # Archived/legacy files
└── README.md                      # This file
```

## 🚀 Quick Start

### For Local Development (KIND)

```bash
# 1. Create KIND cluster
kind create cluster --name owncloud

# 2. Deploy using script (recommended)
./kind/scripts/deploy-kind.sh

# 3. Access ownCloud
kubectl port-forward -n owncloud svc/owncloud 8080:8080
# Open http://localhost:8080
```

See [`kind/README.md`](kind/README.md) for detailed KIND deployment instructions.

### For Production

```bash
# 1. Review and update configurations
# - Update secrets in production/owncloud-secret.yaml
# - Update ingress hostname in production/owncloud-ingress.yaml
# - Verify storage class in production/storageclass.yaml

# 2. Deploy all resources
kubectl apply -f production/

# 3. Verify deployment
kubectl get pods -n owncloud
kubectl get svc -n owncloud
kubectl get ingress -n owncloud
```

> **⚠️ Security Warning**: Before deploying to production, review the [SECURITY.md](SECURITY.md) file for critical security considerations and best practices.

See [`production/README.md`](production/README.md) for detailed production deployment instructions.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Getting Started](#getting-started)
  - [KIND (Local) Deployment](#kind-local-deployment)
  - [Production Deployment](#production-deployment)
- [Configuration Files](#configuration-files)
- [Accessing OwnCloud](#accessing-owncloud)
- [Changelog](#changelog)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## 📝 Changelog

### 2025-11-22 (Latest)
- **Organized**: Separated KIND and production configurations into dedicated folders
- **Added**: Comprehensive README files for both KIND and production deployments
- **Improved**: Project structure for easier deployment and maintenance

### 2025-11-22 (Earlier Updates)
- **Scaled**: OwnCloud deployment to 2 replicas for high availability
- **Updated**: Storage access mode to ReadWriteMany for multi-pod support
- **Added**: Pod anti-affinity to distribute pods across different nodes
- **Added**: PodDisruptionBudget to ensure minimum availability during maintenance
- **Implemented**: ownCloud official best practices for Kubernetes deployments
- **Added**: Comprehensive scaling documentation (`SCALING-NOTES.md`)

### 2025-11-22 (Database Migration)
- **Migrated**: Database from MariaDB to PostgreSQL 17 for better performance and reliability
- **Optimized**: PostgreSQL configuration with OwnCloud best practices
- **Updated**: Redis to version 7.4 (latest stable LTS)
- **Added**: Dynamic storage with volume expansion capabilities
- **Added**: StorageClass configuration for expandable persistent volumes
- **Added**: Comprehensive storage management guide (`STORAGE_MANAGEMENT.md`)
- **Improved**: All PVCs now support dynamic volume expansion without downtime

### 2025-11-20
- **Updated**: Pinned ownCloud server to version 10.16 (latest stable before EOL on Dec 31, 2025)
- **Added**: Resource requests and limits for all deployments (ownCloud, PostgreSQL, Redis)
- **Added**: Liveness and readiness probes for better health monitoring
- **Improved**: Production-ready configuration with proper resource management
- **Fixed**: Renamed `owncloud-namespse.yaml` to `owncloud-namespace.yaml` (corrected typo in filename)
- **Verified**: All Kubernetes manifests are properly structured and deployment-ready

## 🛠️ Prerequisites

Ensure the following prerequisites are met before deploying OwnCloud:

### For KIND (Local Development)
- **KIND**: Kubernetes IN Docker installed
- **kubectl**: Installed and configured
- **Docker**: Running on your machine

### For Production
- **Kubernetes Cluster**: v1.19 or higher
- **kubectl**: Installed and configured to access the cluster
- **Ingress Controller**: Installed (e.g., Nginx, Traefik)
- **Persistent Volume (PV)**: Supported in the infrastructure
- **Storage Class**: Supporting ReadWriteMany for multi-pod deployments (NFS, CephFS, or cloud provider file storage)

## 🏗️ Architecture Overview

The deployment involves several key components:

1. **OwnCloud**: The core application for cloud storage (version 10.16).
2. **PostgreSQL**: Database backend for data management (version 17 - latest stable).
3. **Redis**: Caching service to enhance performance (version 7.4 LTS).
4. **Ingress**: Provides external access to OwnCloud (production only).
5. **Secrets & ConfigMaps**: Manages sensitive information and application configurations.

## 🏁 Getting Started

Choose your deployment environment:

Choose your deployment environment:

### KIND (Local) Deployment

For local development and testing using KIND, see the comprehensive guide in [`kind/README.md`](kind/README.md).

**Quick summary:**
1. Create a KIND cluster
2. Run the deployment script (`deploy-kind.ps1` or `deploy-kind.sh`)
3. Port-forward to access ownCloud locally

### Production Deployment

For production deployment, see the comprehensive guide in [`production/README.md`](production/README.md).

**Quick summary:**
1. Review and update configurations (secrets, ingress, storage)
2. Apply all manifests: `kubectl apply -f production/`
3. Verify deployment and access via ingress

## 🗂️ Configuration Files

### KIND (Local Development)
Located in `kind/` directory:
- Single replica deployment
- ReadWriteOnce storage (local-path provisioner)
- No ingress (use port-forward)
- Optimized for local testing

### Production
Located in `production/` directory:
- 2-replica deployment with high availability
- ReadWriteMany storage for multi-pod access
- Ingress for external access
- Pod anti-affinity and disruption budgets
- Resource limits and health checks

### Common Components
Both environments include:
- **Namespace**: `owncloud-namespace.yaml`
- **Secrets**: `owncloud-secret.yaml` (database credentials)
- **ConfigMap**: `configmap.yaml` (ownCloud configuration)
- **StorageClass**: `storageclass.yaml` (with volume expansion)
- **PostgreSQL**: `postgresql.yaml` (version 17, optimized for ownCloud)
- **Redis**: `redis.yaml` (version 7.4 LTS)
- **OwnCloud**: `owncloud.yaml` (version 10.16)

### Deployment Scripts

**KIND Scripts** (in `kind/scripts/`):
- `deploy-kind.sh` - Automated KIND deployment
- `diagnose-pvc.sh` - PVC troubleshooting utility
- `fix-pvc.sh` - PVC issue resolution

**Production Scripts** (in `production/scripts/`):
- `deploy-argocd.sh` - ArgoCD setup for GitOps

### Documentation

All documentation is located in the `docs/` folder:
- `FOLDER-STRUCTURE.md` - Project structure guide
- `SCALING-NOTES.md` - Scaling configuration and best practices
- `STORAGE_MANAGEMENT.md` - Storage expansion guide
- `TROUBLESHOOT-PVC.md` - PVC troubleshooting
- `KIND-ARGOCD-GUIDE.md` - ArgoCD with KIND setup
- `DEPLOYMENT-CHECKLIST.md` - Pre-deployment checklist
- And more...

## 🌐 Accessing OwnCloud

After deployment, access OwnCloud through the URL specified in the `owncloud-ingress.yaml` file. Ensure DNS is correctly set up to route to the Ingress Controller's external IP.

Default credentials (⚠️ **Change these in production!**):
- **Username**: admin
- **Password**: admin

## ⚠️ Important Notes

### Security & Legal
- **⚠️ EDUCATIONAL USE ONLY**: This project is for learning purposes. Do not use in production without proper security review and hardening.
- **🔐 CHANGE ALL DEFAULTS**: Default passwords (`admin/admin`) are for demonstration only. **NEVER use in production!**
- **🔒 Security Responsibility**: You are solely responsible for securing your deployment, implementing proper authentication, encryption, and access controls.
- **📋 No Warranty**: This software is provided "as is" without any warranty. See [LICENSE](LICENSE) for details.
- **⚖️ Compliance**: Ensure compliance with all applicable laws, regulations, and third-party licenses.

### Technical Considerations
- **ownCloud 10.x End-of-Life**: ownCloud 10 will reach EOL on **December 31, 2025**. Plan migration to ownCloud Infinite Scale (oCIS) for continued support.
- **High Availability Storage**: The deployment uses **ReadWriteMany** access mode for 2-pod scaling. Ensure your storage class supports this (NFS, CephFS, cloud provider file storage). See `docs/SCALING-NOTES.md` for details.
- **Resource Limits**: Adjust resource requests and limits based on your workload requirements.
- **Dynamic Storage**: All persistent volumes support expansion without downtime. See `docs/STORAGE_MANAGEMENT.md` for instructions.
- **Storage Backend**: The default StorageClass uses local provisioner. For production with multiple replicas, use NFS or cloud provider storage classes (AWS EFS, GCP Filestore, Azure Files) for ReadWriteMany support.
- **Pod Distribution**: Pod anti-affinity is configured to distribute ownCloud pods across different nodes for better availability.

## 🤝 Contributing

Contributions are welcome! If you would like to contribute to this project:

1. Fork the repository.
2. Create a new feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## 📧 Contact

For any questions, suggestions, or issues, please reach out:

- **GitHub**: [amrmarey](https://github.com/amrmarey/owncloud-k8s)
- **Email**: [amr.marey@msn.com](mailto:amr.marey@msn.com)
