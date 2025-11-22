# 🔄 ArgoCD Deployment - Step by Step

## 🚀 Quick Start (Automated)

### Option 1: Automated Script (Easiest)

```powershell
# Run the automated ArgoCD deployment script
.\deploy-argocd.ps1
```

This script will:
1. ✅ Check prerequisites
2. ✅ Install ArgoCD (if not already installed)
3. ✅ Ask you to choose deployment mode (KIND or Production)
4. ✅ Create and deploy ArgoCD Application
5. ✅ Wait for all components to be ready
6. ✅ Display access information

---

## 📋 Manual Deployment (Step by Step)

### Step 1: Ensure You Have a Kubernetes Cluster

```bash
# For KIND
kind create cluster --name owncloud

# Verify cluster
kubectl cluster-info
```

### Step 2: Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### Step 3: Access ArgoCD UI (Optional but Recommended)

```bash
# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

Open browser: **https://localhost:8081**

Get admin password:
```bash
# Windows PowerShell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# Linux/Mac
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Login with:
- Username: `admin`
- Password: (from command above)

### Step 4: Deploy ownCloud via ArgoCD

#### For KIND/Local Testing:

```bash
# Apply the KIND-specific ArgoCD application
kubectl apply -f argocd-application-kind.yaml
```

This will deploy:
- ✅ 1 ownCloud replica (ReadWriteOnce storage)
- ✅ PostgreSQL database
- ✅ Redis cache
- ✅ KIND-compatible storage class

#### For Production:

```bash
# Apply the production ArgoCD application
kubectl apply -f argocd-application.yaml
```

This will deploy:
- ✅ 2 ownCloud replicas (ReadWriteMany storage)
- ✅ PostgreSQL database
- ✅ Redis cache
- ✅ Pod anti-affinity
- ✅ PodDisruptionBudget

### Step 5: Monitor Deployment

```bash
# Watch ArgoCD application status
kubectl get application owncloud -n argocd -w

# Watch pods being created
kubectl get pods -n owncloud-namespace -w

# Check ArgoCD application details
kubectl describe application owncloud -n argocd
```

### Step 6: Wait for Sync to Complete

ArgoCD will automatically:
1. Create the namespace
2. Deploy storage class
3. Create secrets and configmap
4. Deploy PostgreSQL
5. Deploy Redis
6. Deploy ownCloud

This typically takes **2-5 minutes**.

### Step 7: Verify Deployment

```bash
# Check all resources are created
kubectl get all -n owncloud-namespace

# Check PVCs are bound
kubectl get pvc -n owncloud-namespace

# Check pods are running
kubectl get pods -n owncloud-namespace

# Expected output:
# NAME                          READY   STATUS    RESTARTS   AGE
# owncloud-xxxxxxxxxx-xxxxx     1/1     Running   0          2m
# postgresql-xxxxxxxxxx-xxxxx   1/1     Running   0          3m
# redis-xxxxxxxxxx-xxxxx        1/1     Running   0          3m
```

### Step 8: Access ownCloud

```bash
# Port forward to ownCloud service
kubectl port-forward -n owncloud-namespace svc/owncloud 8080:80
```

Open browser: **http://localhost:8080**

Login with:
- Username: `admin`
- Password: `admin`

⚠️ **Change the password immediately after first login!**

---

## 🔍 Monitoring with ArgoCD

### View in ArgoCD UI

1. Open ArgoCD UI: https://localhost:8081
2. Click on the `owncloud` application
3. View the application tree showing all resources
4. Check sync status and health

### View via CLI

```bash
# Get application status
kubectl get application owncloud -n argocd

# Describe application
kubectl describe application owncloud -n argocd

# View application in YAML format
kubectl get application owncloud -n argocd -o yaml
```

---

## 🔄 GitOps Workflow

### How It Works

1. **You push changes to Git** (e.g., update image version in `owncloud.yaml`)
2. **ArgoCD detects the change** (polls every 3 minutes by default)
3. **ArgoCD syncs automatically** (because `automated: true` is set)
4. **Kubernetes applies the changes**
5. **Pods are updated** with zero-downtime rolling update

### Manual Sync

If you want to sync immediately:

```bash
# Via kubectl
kubectl patch application owncloud -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

# Or delete and recreate the application
kubectl delete application owncloud -n argocd
kubectl apply -f argocd-application-kind.yaml  # or argocd-application.yaml
```

### Disable Auto-Sync

If you want manual control:

```bash
# Edit the application
kubectl edit application owncloud -n argocd

# Remove or comment out the automated section:
# syncPolicy:
#   automated:
#     prune: true
#     selfHeal: true
```

---

## 🧪 Testing GitOps

### Test 1: Update ownCloud Configuration

1. Edit `configmap.yaml` in your Git repo
2. Change a value (e.g., add a new environment variable)
3. Commit and push to Git
4. Wait 3 minutes or manually sync
5. Verify the change is applied:
   ```bash
   kubectl get configmap owncloud-config -n owncloud-namespace -o yaml
   ```

### Test 2: Self-Healing

1. Manually delete a pod:
   ```bash
   kubectl delete pod -n owncloud-namespace -l app=owncloud
   ```
2. ArgoCD will detect the drift
3. ArgoCD will recreate the pod automatically
4. Verify in ArgoCD UI or:
   ```bash
   kubectl get pods -n owncloud-namespace
   ```

### Test 3: Rollback

1. Make a breaking change in Git
2. ArgoCD syncs and applies it
3. Application breaks
4. Rollback via ArgoCD UI or:
   ```bash
   # Get history
   kubectl get application owncloud -n argocd -o jsonpath='{.status.history}'
   
   # Rollback to previous revision
   # (Use ArgoCD UI for easier rollback)
   ```

---

## 🛠️ Troubleshooting

### Application Not Syncing

```bash
# Check application status
kubectl get application owncloud -n argocd

# Check for errors
kubectl describe application owncloud -n argocd | grep -A 10 "Conditions:"

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=100
```

### Sync Failed

```bash
# View sync status
kubectl get application owncloud -n argocd -o jsonpath='{.status.operationState}'

# Check specific resource that failed
kubectl describe application owncloud -n argocd
```

### Resources Not Created

```bash
# Check if namespace exists
kubectl get namespace owncloud-namespace

# Check ArgoCD can access the repo
kubectl get application owncloud -n argocd -o jsonpath='{.status.sourceType}'

# Verify files exist in repo
# Make sure you've pushed your changes to Git!
```

### Health Status Degraded

```bash
# Check pod status
kubectl get pods -n owncloud-namespace

# Check pod logs
kubectl logs -n owncloud-namespace -l app=owncloud --tail=100

# Check events
kubectl get events -n owncloud-namespace --sort-by='.lastTimestamp'
```

---

## 🧹 Cleanup

### Delete ownCloud Application

```bash
# Delete via ArgoCD (will delete all resources)
kubectl delete application owncloud -n argocd

# Verify resources are deleted
kubectl get all -n owncloud-namespace
```

### Uninstall ArgoCD

```bash
# Delete ArgoCD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Delete namespace
kubectl delete namespace argocd
```

---

## 📊 ArgoCD Application Files

| File | Purpose | Use Case |
|------|---------|----------|
| `argocd-application-kind.yaml` | KIND deployment | Local testing, 1 replica |
| `argocd-application.yaml` | Production deployment | Production, 2 replicas |
| `deploy-argocd.ps1` | Automated script | Quick deployment |

---

## ✅ Success Criteria

After deployment, you should see:

### In ArgoCD UI:
- ✅ Application status: **Healthy**
- ✅ Sync status: **Synced**
- ✅ All resources: **Green**

### In Kubernetes:
```bash
$ kubectl get application owncloud -n argocd
NAME       SYNC STATUS   HEALTH STATUS
owncloud   Synced        Healthy

$ kubectl get pods -n owncloud-namespace
NAME                          READY   STATUS    RESTARTS   AGE
owncloud-xxxxxxxxxx-xxxxx     1/1     Running   0          5m
postgresql-xxxxxxxxxx-xxxxx   1/1     Running   0          6m
redis-xxxxxxxxxx-xxxxx        1/1     Running   0          6m
```

---

## 🎯 Next Steps

1. ✅ Deploy via ArgoCD
2. ✅ Verify application is healthy
3. ✅ Test GitOps workflow (make a change, push to Git)
4. ✅ Test self-healing (delete a pod)
5. ✅ Access ownCloud and test functionality
6. ✅ Monitor with ArgoCD UI

---

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [GitOps Principles](https://opengitops.dev/)

---

**You're ready to deploy with ArgoCD! 🚀**

Run: `.\deploy-argocd.ps1` to get started!
