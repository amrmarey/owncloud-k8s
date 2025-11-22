# 🔧 PVC Binding Issue Fix

## ❌ Problem

```
0/1 nodes are available: 1 node(s) didn't find available persistent volumes to bind
```

This means:
- PersistentVolumeClaims (PVCs) are created
- No PersistentVolumes (PVs) are available to bind to them
- Pods can't start because they need the PVCs

## 🔍 Root Cause

KIND doesn't have a default storage provisioner installed by default. The `storageclass.yaml` in the `kind/` directory uses `rancher.io/local-path` provisioner, but it might not be installed.

## ✅ Solution

### Option 1: Install Rancher Local Path Provisioner (Recommended)

```bash
# Install the local-path provisioner
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# Wait for it to be ready
kubectl wait --for=condition=ready pod -l app=local-path-provisioner -n local-path-storage --timeout=60s

# Verify it's running
kubectl get pods -n local-path-storage
```

### Option 2: Use KIND's Built-in Standard Storage Class

Update the storage class in `kind/storageclass.yaml`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: owncloud-storage
provisioner: rancher.io/local-path  # This is correct for KIND
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
```

But first, check if the provisioner exists:

```bash
# Check if local-path provisioner is running
kubectl get pods -n local-path-storage

# Check available storage classes
kubectl get storageclass
```

## 🚀 Quick Fix Steps

### Step 1: Check Current Status

```bash
# Check PVCs
kubectl get pvc -n owncloud-namespace

# Check PVs
kubectl get pv

# Check storage classes
kubectl get storageclass

# Check if local-path provisioner exists
kubectl get pods -n local-path-storage
```

### Step 2: Install Local Path Provisioner

```bash
# Install it
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# Verify installation
kubectl get pods -n local-path-storage
kubectl get storageclass
```

### Step 3: Delete and Recreate PVCs (if needed)

```bash
# Delete stuck PVCs
kubectl delete pvc --all -n owncloud-namespace

# Trigger ArgoCD to recreate them
kubectl delete application owncloud -n argocd
kubectl apply -f argocd-application-kind.yaml
```

### Step 4: Verify PVCs Bind

```bash
# Watch PVCs bind
kubectl get pvc -n owncloud-namespace -w

# Should show STATUS: Bound after a few seconds
```

## 🔍 Diagnostic Commands

### Check PVC Status

```bash
# Get PVC details
kubectl get pvc -n owncloud-namespace

# Describe a specific PVC to see events
kubectl describe pvc files-pvc -n owncloud-namespace
kubectl describe pvc postgresql-pvc -n owncloud-namespace
kubectl describe pvc redis-pvc -n owncloud-namespace
```

### Check Storage Class

```bash
# List storage classes
kubectl get storageclass

# Expected output should include:
# NAME               PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION
# owncloud-storage   rancher.io/local-path   Delete          WaitForFirstConsumer   true
# standard           rancher.io/local-path   Delete          WaitForFirstConsumer   true
```

### Check Provisioner

```bash
# Check if local-path provisioner is running
kubectl get pods -n local-path-storage

# Should show:
# NAME                                     READY   STATUS    RESTARTS   AGE
# local-path-provisioner-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
```

## 📝 Alternative: Use Standard Storage Class

If you want to use KIND's default storage class instead:

### Update `kind/storageclass.yaml`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: owncloud-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
```

Or simply use the `standard` storage class that comes with KIND:

### Update all PVCs in `kind/` directory:

Change `storageClassName: owncloud-storage` to `storageClassName: standard`

## 🎯 Complete Fix Script

```bash
#!/bin/bash

echo "🔧 Fixing PVC binding issue..."

# 1. Install local-path provisioner
echo "📦 Installing local-path provisioner..."
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# 2. Wait for provisioner to be ready
echo "⏳ Waiting for provisioner..."
kubectl wait --for=condition=ready pod -l app=local-path-provisioner -n local-path-storage --timeout=60s

# 3. Verify storage class exists
echo "✅ Checking storage class..."
kubectl get storageclass

# 4. Delete stuck PVCs
echo "🗑️ Cleaning up stuck PVCs..."
kubectl delete pvc --all -n owncloud-namespace 2>/dev/null || true

# 5. Restart ArgoCD sync
echo "🔄 Resyncing ArgoCD application..."
kubectl delete application owncloud -n argocd 2>/dev/null || true
sleep 5
kubectl apply -f argocd-application-kind.yaml

# 6. Wait and verify
echo "⏳ Waiting for PVCs to bind..."
sleep 10
kubectl get pvc -n owncloud-namespace

echo "✅ Done! Check PVC status above."
```

Save this as `fix-pvc.sh`, make it executable, and run it:

```bash
chmod +x fix-pvc.sh
./fix-pvc.sh
```

## ✅ Expected Result

After the fix, you should see:

```bash
$ kubectl get pvc -n owncloud-namespace

NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE
files-pvc        Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   10Gi       RWO            owncloud-storage   1m
postgresql-pvc   Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   10Gi       RWO            owncloud-storage   1m
redis-pvc        Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   5Gi        RWO            owncloud-storage   1m
```

All should show `STATUS: Bound`

## 🎓 Why This Happens

1. **KIND doesn't include storage provisioner by default** in some versions
2. **PVCs need a provisioner** to dynamically create PVs
3. **Without provisioner**, PVCs stay in `Pending` state
4. **Pods can't start** without bound PVCs

## 📚 Next Steps

1. ✅ Install local-path provisioner
2. ✅ Verify storage class exists
3. ✅ Delete and recreate PVCs
4. ✅ Verify PVCs bind successfully
5. ✅ Pods should start automatically

---

**Quick fix: Run this command first!**

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

Then wait a minute and check:

```bash
kubectl get pvc -n owncloud-namespace
```

They should bind automatically! 🚀
