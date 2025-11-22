# 🚀 Deployment Scripts - Quick Reference

## 📁 Available Scripts

### For WSL/Ubuntu/Linux (Bash)
- ✅ `deploy-kind.sh` - Deploy ownCloud on KIND
- ✅ `deploy-argocd.sh` - Deploy ownCloud via ArgoCD

### For Windows (PowerShell)
- ✅ `deploy-kind.ps1` - Deploy ownCloud on KIND
- ✅ `deploy-argocd.ps1` - Deploy ownCloud via ArgoCD

---

## 🐧 WSL/Ubuntu Usage

### Make Scripts Executable (First Time Only)

```bash
# Navigate to project directory
cd /mnt/d/Projects/owncloud-k8s

# Make scripts executable
chmod +x deploy-kind.sh
chmod +x deploy-argocd.sh
```

### Deploy on KIND

```bash
# Run the KIND deployment script
./deploy-kind.sh
```

### Deploy via ArgoCD

```bash
# Run the ArgoCD deployment script
./deploy-argocd.sh
```

---

## 💻 Windows PowerShell Usage

### Deploy on KIND

```powershell
# Navigate to project directory
cd D:\Projects\owncloud-k8s

# Run the KIND deployment script
.\deploy-kind.ps1
```

### Deploy via ArgoCD

```powershell
# Run the ArgoCD deployment script
.\deploy-argocd.ps1
```

---

## 🎯 What Each Script Does

### `deploy-kind.sh` / `deploy-kind.ps1`

**Automated KIND Deployment**

1. ✅ Checks prerequisites (Docker, KIND, kubectl)
2. ✅ Creates KIND cluster with ingress support
3. ✅ Installs nginx ingress controller
4. ✅ Deploys complete ownCloud stack:
   - Namespace
   - Storage class (KIND-compatible)
   - Secrets
   - ConfigMap
   - PostgreSQL
   - Redis
   - ownCloud (1 replica)
5. ✅ Waits for all components to be ready
6. ✅ Displays access information

**Time**: ~5 minutes

### `deploy-argocd.sh` / `deploy-argocd.ps1`

**Automated ArgoCD Deployment**

1. ✅ Checks prerequisites
2. ✅ Installs ArgoCD (if not already installed)
3. ✅ Asks for deployment mode (KIND or Production)
4. ✅ Creates ArgoCD Application
5. ✅ Waits for sync to complete
6. ✅ Displays access information for ArgoCD UI and ownCloud

**Time**: ~7 minutes (includes ArgoCD installation)

---

## 🔧 Troubleshooting

### WSL: Permission Denied

```bash
# If you get "Permission denied" error
chmod +x deploy-kind.sh
chmod +x deploy-argocd.sh
```

### WSL: Line Ending Issues

If scripts fail with `\r` errors:

```bash
# Convert Windows line endings to Unix
sed -i 's/\r$//' deploy-kind.sh
sed -i 's/\r$//' deploy-argocd.sh
```

Or use `dos2unix`:

```bash
# Install dos2unix if needed
sudo apt-get install dos2unix

# Convert files
dos2unix deploy-kind.sh
dos2unix deploy-argocd.sh
```

### PowerShell: Execution Policy

If you get "cannot be loaded because running scripts is disabled":

```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current user (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run with bypass (one-time)
powershell -ExecutionPolicy Bypass -File .\deploy-kind.ps1
```

---

## 📊 Comparison

| Feature | KIND Script | ArgoCD Script |
|---------|-------------|---------------|
| Deployment Method | Direct kubectl apply | GitOps via ArgoCD |
| Setup Time | ~5 min | ~7 min (first time) |
| GitOps Support | ❌ No | ✅ Yes |
| Auto-sync | ❌ No | ✅ Yes |
| Self-healing | ❌ No | ✅ Yes |
| UI Dashboard | ❌ No | ✅ Yes (ArgoCD UI) |
| Best For | Quick testing | Production, GitOps workflow |

---

## 🎓 Recommendations

### For Quick Testing
Use **KIND scripts** (`deploy-kind.sh` or `deploy-kind.ps1`)
- Fastest way to get started
- No ArgoCD overhead
- Good for learning and testing

### For Production/GitOps
Use **ArgoCD scripts** (`deploy-argocd.sh` or `deploy-argocd.ps1`)
- GitOps best practices
- Automated sync from Git
- Self-healing capabilities
- Better for team collaboration

### For WSL Users
Use **bash scripts** (`.sh` files)
- Native Linux environment
- Better compatibility
- Easier to debug

### For Windows Users
Use **PowerShell scripts** (`.ps1` files)
- Native Windows environment
- No WSL required
- Works with Windows Terminal

---

## ✅ Quick Start Commands

### WSL/Ubuntu (Recommended for You)

```bash
# Make scripts executable (first time only)
chmod +x *.sh

# Option 1: Deploy with KIND
./deploy-kind.sh

# Option 2: Deploy with ArgoCD
./deploy-argocd.sh
```

### Windows PowerShell

```powershell
# Option 1: Deploy with KIND
.\deploy-kind.ps1

# Option 2: Deploy with ArgoCD
.\deploy-argocd.ps1
```

---

## 🧹 Cleanup

### Remove ownCloud Deployment

```bash
# If deployed with KIND script
kubectl delete -f owncloud-kind.yaml
kubectl delete -f redis.yaml
kubectl delete -f postgresql.yaml
kubectl delete -f configmap.yaml
kubectl delete -f owncloud-secret.yaml
kubectl delete namespace owncloud-namespace

# If deployed with ArgoCD
kubectl delete application owncloud -n argocd
```

### Delete KIND Cluster

```bash
kind delete cluster --name owncloud
```

### Uninstall ArgoCD

```bash
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
```

---

## 📚 Next Steps

1. Choose your deployment method (KIND or ArgoCD)
2. Choose your environment (WSL/Ubuntu or PowerShell)
3. Run the appropriate script
4. Access ownCloud and test functionality
5. Explore the ArgoCD UI (if using ArgoCD)

---

**Ready to deploy! 🚀**

For WSL/Ubuntu: `./deploy-argocd.sh`  
For PowerShell: `.\deploy-argocd.ps1`
