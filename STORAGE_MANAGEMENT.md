# Storage Management Guide

## Overview
The OwnCloud Kubernetes deployment now uses dynamic storage with volume expansion capabilities. This allows you to increase storage capacity without recreating volumes or losing data.

## Current Storage Allocations
- **Redis**: 5Gi
- **MariaDB**: 10Gi
- **OwnCloud Files**: 10Gi

## How to Expand Storage

### Step 1: Apply the StorageClass (First Time Only)
```bash
kubectl apply -f storageclass.yaml
```

### Step 2: Expand a Volume
To increase storage for any component, edit the corresponding YAML file and update the storage size in the PVC section.

#### Example: Expanding MariaDB storage from 10Gi to 20Gi

1. Edit `mariadb.yaml`:
```yaml
spec:
  storageClassName: owncloud-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi  # Changed from 10Gi to 20Gi
```

2. Apply the changes:
```bash
kubectl apply -f mariadb.yaml
```

3. Verify the expansion:
```bash
kubectl get pvc mysql-pvc -n owncloud-namespace
```

### Step 3: Monitor the Expansion
The expansion happens automatically. You can monitor the status:
```bash
kubectl describe pvc <pvc-name> -n owncloud-namespace
```

Look for events indicating the volume is being resized.

## Important Notes

1. **You can only INCREASE storage size**, not decrease it
2. **No downtime required** - the volume expands while the pod is running
3. **The pod may need to be restarted** in some cases for the filesystem to recognize the new size
4. **Supported storage backends**: This works with most cloud providers (AWS EBS, GCP PD, Azure Disk) and some on-premises storage solutions

## Troubleshooting

### If expansion doesn't work:
1. Check if your storage backend supports volume expansion
2. Verify the StorageClass has `allowVolumeExpansion: true`
3. Check PVC status: `kubectl describe pvc <pvc-name> -n owncloud-namespace`
4. Review events: `kubectl get events -n owncloud-namespace`

### For cloud-specific storage classes:
If you're using a cloud provider, you may want to use their default storage class instead:

**AWS (EBS):**
```yaml
storageClassName: gp3  # or gp2
```

**GCP (Persistent Disk):**
```yaml
storageClassName: standard  # or pd-ssd
```

**Azure (Disk):**
```yaml
storageClassName: managed-premium  # or default
```

Simply replace `owncloud-storage` with the appropriate cloud storage class in your PVC definitions.
