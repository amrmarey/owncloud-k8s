
# 🌥️ OwnCloud on Kubernetes

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.19+-blue.svg)](https://kubernetes.io/)
[![Helm 3](https://img.shields.io/badge/Helm-3.x-orange.svg)](https://helm.sh/)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Deploy an **OwnCloud** instance on a Kubernetes cluster using the provided manifests. This setup leverages **MariaDB** as a database backend, **Redis** for caching, and uses Kubernetes **Ingress** for managing external access.

## 🚀 Features

- **High Availability**: 2-pod deployment with automatic failover and load balancing
- **Scalable Deployment**: Deploy OwnCloud with Kubernetes to easily scale horizontally
- **Production Ready**: Includes resource limits, health checks, pod disruption budgets, and anti-affinity rules
- **Secure Storage**: Manages sensitive data using Kubernetes Secrets
- **Shared Storage**: ReadWriteMany access mode for multi-pod data access
- **Customizable Configuration**: Easily configure the setup with ConfigMaps
- **Optimized Performance**: Uses Redis for caching and session management
- **Best Practices**: Follows ownCloud's official Kubernetes deployment recommendations

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Getting Started](#getting-started)
  - [Step 1: Create Namespace](#step-1-create-namespace)
  - [Step 2: Create Secrets](#step-2-create-secrets)
  - [Step 3: Deploy PostgreSQL](#step-3-deploy-postgresql)
  - [Step 4: Deploy Redis](#step-4-deploy-redis)
  - [Step 5: Deploy OwnCloud ConfigMap](#step-5-deploy-owncloud-configmap)
  - [Step 6: Deploy OwnCloud](#step-6-deploy-owncloud)
  - [Step 7: Deploy Ingress](#step-7-deploy-ingress)
- [Configuration Files](#configuration-files)
- [Accessing OwnCloud](#accessing-owncloud)
- [Changelog](#changelog)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## 📝 Changelog

### 2025-11-22 (Latest)
- **Scaled**: OwnCloud deployment to 2 replicas for high availability
- **Updated**: Storage access mode to ReadWriteMany for multi-pod support
- **Added**: Pod anti-affinity to distribute pods across different nodes
- **Added**: PodDisruptionBudget to ensure minimum availability during maintenance
- **Implemented**: ownCloud official best practices for Kubernetes deployments
- **Added**: Comprehensive scaling documentation (`SCALING-NOTES.md`)

### 2025-11-22 (Earlier)
- **Migrated**: Database from MariaDB to PostgreSQL 17 for better performance and reliability
- **Optimized**: PostgreSQL configuration with OwnCloud best practices
- **Updated**: Redis to version 7.4 (latest stable LTS)
- **Added**: Dynamic storage with volume expansion capabilities
- **Added**: StorageClass configuration for expandable persistent volumes
- **Added**: Comprehensive storage management guide (`STORAGE_MANAGEMENT.md`)
- **Improved**: All PVCs now support dynamic volume expansion without downtime

### 2025-11-20
- **Updated**: Pinned ownCloud server to version 10.16 (latest stable before EOL on Dec 31, 2025)
- **Added**: Resource requests and limits for all deployments (ownCloud, MariaDB, Redis)
- **Added**: Liveness and readiness probes for better health monitoring
- **Improved**: Production-ready configuration with proper resource management
- **Fixed**: Renamed `owncloud-namespse.yaml` to `owncloud-namespace.yaml` (corrected typo in filename)
- **Verified**: All Kubernetes manifests are properly structured and deployment-ready
- **Note**: MariaDB 10.11 and Redis 6 versions confirmed as recommended versions

## 🛠️ Prerequisites

Ensure the following prerequisites are met before deploying OwnCloud:

- **Kubernetes Cluster**: v1.19 or higher
- **kubectl**: Installed and configured to access the cluster
- **Helm**: Version 3.x (optional)
- **Ingress Controller**: Installed (e.g., Nginx, Traefik)
- **Persistent Volume (PV)**: Supported in the infrastructure

## 🏗️ Architecture Overview

The deployment involves several key components:

1. **OwnCloud**: The core application for cloud storage (version 10.16).
2. **PostgreSQL**: Database backend for data management (version 17 - latest stable).
3. **Redis**: Caching service to enhance performance (version 7.4 LTS).
4. **Ingress**: Provides external access to OwnCloud.
5. **Secrets & ConfigMaps**: Manages sensitive information and application configurations.

## 🏁 Getting Started

Follow these steps to deploy OwnCloud in your Kubernetes environment.

### Step 1: Create Namespace

Create a dedicated namespace for the OwnCloud deployment:

\`\`\`bash
kubectl apply -f owncloud-namespace.yaml
\`\`\`

### Step 2: Create StorageClass

Apply the StorageClass to enable dynamic volume expansion:

\`\`\`bash
kubectl apply -f storageclass.yaml
\`\`\`

**Note**: If you're using a cloud provider (AWS, GCP, Azure), you may want to use their default storage class instead. See `STORAGE_MANAGEMENT.md` for details.

### Step 3: Create Secrets

Apply the secrets manifest to manage sensitive data:

\`\`\`bash
kubectl apply -f owncloud-secret.yaml
\`\`\`

### Step 4: Deploy PostgreSQL

Deploy the PostgreSQL database backend:

\`\`\`bash
kubectl apply -f postgresql.yaml
\`\`\`

### Step 5: Deploy Redis

Set up Redis for caching:

\`\`\`bash
kubectl apply -f redis.yaml
\`\`\`

### Step 6: Deploy OwnCloud ConfigMap

Apply the ConfigMap to configure OwnCloud settings:

\`\`\`bash
kubectl apply -f configmap.yaml
\`\`\`

### Step 7: Deploy OwnCloud

Deploy the OwnCloud instance:

\`\`\`bash
kubectl apply -f owncloud.yaml
\`\`\`

### Step 8: Deploy Ingress

Set up the Ingress to manage external access:

\`\`\`bash
kubectl apply -f owncloud-ingress.yaml
\`\`\`

## 🗂️ Configuration Files

The repository includes the following configuration files:

- `owncloud-namespace.yaml`: Namespace definition.
- `storageclass.yaml`: StorageClass with dynamic volume expansion enabled.
- `owncloud-secret.yaml`: Secrets for sensitive data.
- `postgresql.yaml`: PostgreSQL 17 deployment optimized for OwnCloud with health checks, resource limits, and expandable storage (10Gi).
- `redis.yaml`: Redis 7.4 LTS deployment with health checks, resource limits, and expandable storage (5Gi).
- `configmap.yaml`: ConfigMap for OwnCloud configuration (PostgreSQL settings).
- `owncloud.yaml`: OwnCloud 10.16 deployment with **2 replicas**, pod anti-affinity, PodDisruptionBudget, health checks, resource limits, and expandable ReadWriteMany storage (10Gi).
- `owncloud-ingress.yaml`: Ingress resource for external access.
- `STORAGE_MANAGEMENT.md`: Comprehensive guide for managing and expanding storage volumes.
- `SCALING-NOTES.md`: Detailed documentation on scaling configuration and ownCloud best practices.

## 🌐 Accessing OwnCloud

After deployment, access OwnCloud through the URL specified in the `owncloud-ingress.yaml` file. Ensure DNS is correctly set up to route to the Ingress Controller's external IP.

Default credentials (⚠️ **Change these in production!**):
- **Username**: admin
- **Password**: admin

## ⚠️ Important Notes

- **ownCloud 10.x End-of-Life**: ownCloud 10 will reach EOL on **December 31, 2025**. Plan migration to ownCloud Infinite Scale (oCIS) for continued support.
- **High Availability Storage**: The deployment uses **ReadWriteMany** access mode for 2-pod scaling. Ensure your storage class supports this (NFS, CephFS, cloud provider file storage). See `SCALING-NOTES.md` for details.
- **Security**: Change default passwords in `owncloud-secret.yaml` before deploying to production.
- **Resource Limits**: Adjust resource requests and limits based on your workload requirements.
- **Dynamic Storage**: All persistent volumes support expansion without downtime. See `STORAGE_MANAGEMENT.md` for instructions on how to increase storage capacity.
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
