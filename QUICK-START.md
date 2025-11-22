# 🎯 Quick Start Guide - Testing on KIND

## 🚀 Fastest Way to Get Started

### Option 1: Automated Deployment (Recommended)

```powershell
# Run the automated deployment script
.\deploy-kind.ps1
```

This script will:
1. ✅ Check prerequisites (Docker, KIND, kubectl)
2. ✅ Create KIND cluster with ingress support
3. ✅ Install nginx ingress controller
4. ✅ Deploy complete ownCloud stack
5. ✅ Wait for all components to be ready
6. ✅ Display access information

### Option 2: Manual Step-by-Step

```bash
# 1. Create KIND cluster
kind create cluster --name owncloud

# 2. Deploy in order
kubectl apply -f owncloud-namespace.yaml
kubectl apply -f storageclass-kind.yaml
kubectl apply -f owncloud-secret.yaml
kubectl apply -f configmap.yaml
kubectl apply -f postgresql.yaml
kubectl apply -f redis.yaml

# Wait for database
kubectl wait --for=condition=ready pod -l app=postgresql -n owncloud-namespace --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n owncloud-namespace --timeout=300s

# Deploy ownCloud
kubectl apply -f owncloud-kind.yaml
kubectl wait --for=condition=ready pod -l app=owncloud -n owncloud-namespace --timeout=300s

# Access ownCloud
kubectl port-forward -n owncloud-namespace svc/owncloud 8080:80
```

Then open: http://localhost:8080

---

## 📁 Files Overview

### For KIND Testing (Use These)
- ✅ `owncloud-namespace.yaml`
- ✅ `storageclass-kind.yaml` ⭐ (KIND-specific)
- ✅ `owncloud-secret.yaml`
- ✅ `configmap.yaml`
- ✅ `postgresql.yaml` (Fixed!)
- ✅ `redis.yaml`
- ✅ `owncloud-kind.yaml` ⭐ (KIND-specific, 1 replica)

### For Production (Don't Use on KIND)
- ⚠️ `owncloud.yaml` (Requires ReadWriteMany storage)
- ⚠️ `storageclass.yaml` (Uses no-provisioner)

### For ArgoCD
- ✅ `argocd-application.yaml`

---

## 🔧 What Was Fixed

### Critical Issues Resolved ✅

1. **PostgreSQL Namespace** - Changed from `owncloud` to `owncloud-namespace`
2. **PostgreSQL Secret Name** - Changed from `owncloud-secret` to `owncloud-secrets`
3. **PostgreSQL Secret Keys** - Fixed to use `OWNCLOUD_DB_PASSWORD`
4. **KIND Compatibility** - Created KIND-specific storage and deployment files

---

## 📊 Expected Results

After deployment, you should see:

```bash
$ kubectl get pods -n owncloud-namespace

NAME                          READY   STATUS    RESTARTS   AGE
owncloud-xxxxxxxxxx-xxxxx     1/1     Running   0          2m
postgresql-xxxxxxxxxx-xxxxx   1/1     Running   0          3m
redis-xxxxxxxxxx-xxxxx        1/1     Running   0          3m
```

```bash
$ kubectl get pvc -n owncloud-namespace

NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES
files-pvc        Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   10Gi       RWO
postgresql-pvc   Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   10Gi       RWO
redis-pvc        Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   5Gi        RWO
```

---

## 🌐 Access ownCloud

### Method 1: Port Forward (Easiest)

```bash
kubectl port-forward -n owncloud-namespace svc/owncloud 8080:80
```

Access at: **http://localhost:8080**

### Method 2: NodePort

```bash
# Get the NodePort
kubectl get svc owncloud -n owncloud-namespace

# Access at http://localhost:<NodePort>
```

### Default Credentials
- **Username**: admin
- **Password**: admin

⚠️ **Change these immediately after first login!**

---

## 🧪 Testing Checklist

- [ ] All pods are running
- [ ] All PVCs are bound
- [ ] Can access ownCloud UI
- [ ] Can login with default credentials
- [ ] Can create a test user
- [ ] Can upload a file
- [ ] Can download a file
- [ ] Can delete a file
- [ ] Pod recreation works (delete pod, verify it recreates)
- [ ] Data persists after pod deletion

---

## 🔍 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n owncloud-namespace

# Check pod logs
kubectl logs -n owncloud-namespace -l app=owncloud --tail=100
kubectl logs -n owncloud-namespace -l app=postgresql --tail=100
kubectl logs -n owncloud-namespace -l app=redis --tail=100

# Describe pod for events
kubectl describe pod -n owncloud-namespace -l app=owncloud
```

### PVC Not Binding

```bash
# Check PVC status
kubectl get pvc -n owncloud-namespace

# Check storage class
kubectl get storageclass

# Verify local-path provisioner is running
kubectl get pods -n local-path-storage
```

### Can't Access ownCloud

```bash
# Verify service exists
kubectl get svc -n owncloud-namespace owncloud

# Check if pod is ready
kubectl get pods -n owncloud-namespace -l app=owncloud

# Try port-forward directly to pod
kubectl port-forward -n owncloud-namespace $(kubectl get pod -n owncloud-namespace -l app=owncloud -o jsonpath='{.items[0].metadata.name}') 8080:8080
```

---

## 🧹 Cleanup

### Delete Everything

```bash
# Delete all resources
kubectl delete -f owncloud-kind.yaml
kubectl delete -f redis.yaml
kubectl delete -f postgresql.yaml
kubectl delete -f configmap.yaml
kubectl delete -f owncloud-secret.yaml
kubectl delete -f storageclass-kind.yaml
kubectl delete namespace owncloud-namespace

# Or delete the entire cluster
kind delete cluster --name owncloud
```

---

## 📚 Documentation

- **Full Review**: `FINAL-REVIEW.md` - Complete review report
- **KIND/ArgoCD Guide**: `KIND-ARGOCD-GUIDE.md` - Detailed deployment guide
- **Deployment Checklist**: `DEPLOYMENT-CHECKLIST.md` - Validation checklist
- **Scaling Notes**: `SCALING-NOTES.md` - Production scaling guide
- **Main README**: `README.md` - Project overview

---

## ✅ You're Ready!

All critical issues have been fixed. Your deployment is ready for testing on KIND and ArgoCD.

**Start with**: `.\deploy-kind.ps1`

Good luck! 🚀
