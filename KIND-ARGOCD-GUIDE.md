# KIND & ArgoCD Deployment Guide

## 🎯 Overview

This guide provides step-by-step instructions for deploying ownCloud on KIND (Kubernetes IN Docker) and managing it with ArgoCD.

## 📋 Prerequisites

- Docker Desktop installed and running
- KIND installed ([installation guide](https://kind.sigs.k8s.io/docs/user/quick-start/#installation))
- kubectl installed
- ArgoCD CLI (optional but recommended)

## 🚀 Part 1: KIND Cluster Setup

### Step 1: Create KIND Cluster

Create a KIND cluster with ingress support:

```bash
# Create a KIND cluster with extra port mappings for ingress
cat <<EOF | kind create cluster --name owncloud --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
```

### Step 2: Verify Cluster

```bash
# Check cluster status
kubectl cluster-info --context kind-owncloud

# Verify nodes
kubectl get nodes
```

### Step 3: Install Nginx Ingress Controller

```bash
# Install nginx ingress controller for KIND
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

## 📦 Part 2: Deploy ownCloud on KIND

### Option A: Manual Deployment (Recommended for Testing)

```bash
# 1. Create namespace
kubectl apply -f owncloud-namespace.yaml

# 2. Create storage class (KIND-specific)
kubectl apply -f storageclass-kind.yaml

# 3. Create secrets
kubectl apply -f owncloud-secret.yaml

# 4. Create ConfigMap
kubectl apply -f configmap.yaml

# 5. Deploy PostgreSQL
kubectl apply -f postgresql.yaml

# 6. Deploy Redis
kubectl apply -f redis.yaml

# 7. Deploy ownCloud (KIND version with ReadWriteOnce)
kubectl apply -f owncloud-kind.yaml

# 8. Wait for all pods to be ready
kubectl wait --for=condition=ready pod -l app=owncloud -n owncloud-namespace --timeout=300s
kubectl wait --for=condition=ready pod -l app=postgresql -n owncloud-namespace --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n owncloud-namespace --timeout=300s
```

### Option B: Deploy All at Once

```bash
# Deploy everything in order
kubectl apply -f owncloud-namespace.yaml
kubectl apply -f storageclass-kind.yaml
kubectl apply -f owncloud-secret.yaml
kubectl apply -f configmap.yaml
kubectl apply -f postgresql.yaml
kubectl apply -f redis.yaml
kubectl apply -f owncloud-kind.yaml
```

### Verify Deployment

```bash
# Check all resources
kubectl get all -n owncloud-namespace

# Check PVCs
kubectl get pvc -n owncloud-namespace

# Check pod logs
kubectl logs -n owncloud-namespace -l app=owncloud --tail=50
kubectl logs -n owncloud-namespace -l app=postgresql --tail=50
kubectl logs -n owncloud-namespace -l app=redis --tail=50
```

### Access ownCloud

Since we're using KIND, access via NodePort:

```bash
# Get the NodePort
kubectl get svc owncloud -n owncloud-namespace

# Access via localhost
# http://localhost:<NodePort>
```

Or set up port forwarding:

```bash
# Port forward to access on localhost:8080
kubectl port-forward -n owncloud-namespace svc/owncloud 8080:80

# Access at: http://localhost:8080
```

## 🔄 Part 3: ArgoCD Setup

### Step 1: Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### Step 2: Access ArgoCD UI

```bash
# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8081:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access ArgoCD UI at: https://localhost:8081
# Username: admin
# Password: (from command above)
```

### Step 3: Install ArgoCD CLI (Optional)

```bash
# Login via CLI
argocd login localhost:8081 --insecure

# Change password
argocd account update-password
```

## 📂 Part 4: Deploy ownCloud via ArgoCD

### Option 1: Using ArgoCD UI

1. Open ArgoCD UI (https://localhost:8081)
2. Click "NEW APP"
3. Fill in details:
   - **Application Name**: owncloud
   - **Project**: default
   - **Sync Policy**: Automatic (or Manual for testing)
   - **Repository URL**: Your Git repository URL
   - **Path**: . (root of repo)
   - **Cluster**: https://kubernetes.default.svc
   - **Namespace**: owncloud-namespace
4. Click "CREATE"

### Option 2: Using ArgoCD CLI

Create an ArgoCD Application manifest:

```bash
# Create argocd-application.yaml
cat > argocd-application.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: owncloud
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/amrmarey/owncloud-k8s.git
    targetRevision: HEAD
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: owncloud-namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
  # Sync order to ensure dependencies are created first
  syncWaves:
    - name: namespace
      order: 0
    - name: storage
      order: 1
    - name: secrets
      order: 2
    - name: database
      order: 3
    - name: cache
      order: 4
    - name: app
      order: 5
EOF

# Apply the application
kubectl apply -f argocd-application.yaml
```

### Sync Application

```bash
# Via CLI
argocd app sync owncloud

# Check status
argocd app get owncloud

# Watch sync progress
argocd app wait owncloud --health
```

## 🔍 Monitoring & Troubleshooting

### Check Application Status

```bash
# ArgoCD application status
argocd app get owncloud

# Kubernetes resources
kubectl get all -n owncloud-namespace

# Pod status
kubectl get pods -n owncloud-namespace -o wide

# Events
kubectl get events -n owncloud-namespace --sort-by='.lastTimestamp'
```

### Common Issues

#### 1. Pods Stuck in Pending

**Cause**: PVC not bound

```bash
# Check PVC status
kubectl get pvc -n owncloud-namespace

# Describe PVC for details
kubectl describe pvc -n owncloud-namespace
```

**Solution**: Ensure storage class is created and KIND's local-path provisioner is running

```bash
kubectl get storageclass
kubectl get pods -n local-path-storage
```

#### 2. ownCloud Pod CrashLoopBackOff

**Cause**: Database not ready or configuration issue

```bash
# Check PostgreSQL logs
kubectl logs -n owncloud-namespace -l app=postgresql --tail=100

# Check ownCloud logs
kubectl logs -n owncloud-namespace -l app=owncloud --tail=100
```

**Solution**: Wait for PostgreSQL to be fully ready, then restart ownCloud pod

```bash
kubectl delete pod -n owncloud-namespace -l app=owncloud
```

#### 3. Cannot Access ownCloud

**Cause**: Service not exposed correctly

```bash
# Check service
kubectl get svc -n owncloud-namespace owncloud

# Port forward manually
kubectl port-forward -n owncloud-namespace svc/owncloud 8080:80
```

## 🧹 Cleanup

### Delete ownCloud Application

```bash
# Via ArgoCD
argocd app delete owncloud

# Or manually
kubectl delete -f owncloud-kind.yaml
kubectl delete -f redis.yaml
kubectl delete -f postgresql.yaml
kubectl delete -f configmap.yaml
kubectl delete -f owncloud-secret.yaml
kubectl delete -f storageclass-kind.yaml
kubectl delete namespace owncloud-namespace
```

### Delete KIND Cluster

```bash
kind delete cluster --name owncloud
```

## 📝 Important Notes for KIND Testing

### Storage Limitations

- **ReadWriteOnce Only**: KIND's default storage doesn't support ReadWriteMany
- **Single Replica**: Use `owncloud-kind.yaml` which has 1 replica
- **For Production**: Use the main `owncloud.yaml` with NFS or cloud storage

### Resource Constraints

KIND runs in Docker, so:
- Adjust resource limits if needed (in Docker Desktop settings)
- PostgreSQL memory settings may need reduction for low-resource machines
- Monitor Docker resource usage

### Networking

- Ingress works via localhost (ports 80/443)
- NodePort services accessible via `localhost:<NodePort>`
- Port forwarding is most reliable for testing

## 🎓 Next Steps

1. **Test the deployment** thoroughly in KIND
2. **Verify ArgoCD sync** works correctly
3. **Test failover** by deleting pods
4. **Test data persistence** by deleting and recreating pods
5. **Prepare for production** with proper storage (NFS/cloud)

## 📚 References

- [KIND Documentation](https://kind.sigs.k8s.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ownCloud Documentation](https://doc.owncloud.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
