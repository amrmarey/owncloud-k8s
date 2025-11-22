# Pre-Deployment Validation Checklist

## ✅ Configuration Review Checklist

### 1. Namespace Consistency
- [x] All resources use `owncloud-namespace`
- [x] PostgreSQL namespace fixed from `owncloud` to `owncloud-namespace`
- [x] Redis uses correct namespace
- [x] ownCloud uses correct namespace
- [x] Secrets use correct namespace
- [x] ConfigMap uses correct namespace
- [x] Ingress uses correct namespace

### 2. Secret References
- [x] PostgreSQL references `owncloud-secrets` (fixed from `owncloud-secret`)
- [x] PostgreSQL uses correct secret key: `OWNCLOUD_DB_PASSWORD`
- [x] ownCloud references `owncloud-secrets` via envFrom
- [x] All secret keys match the defined secret

### 3. Service Names & Connectivity
- [x] PostgreSQL service: `postgresql` (referenced in configmap)
- [x] Redis service: `redis` (referenced in configmap)
- [x] ownCloud service: `owncloud` (referenced in ingress)
- [x] All services in same namespace

### 4. Storage Configuration

#### Production (owncloud.yaml)
- [x] Uses ReadWriteMany for multi-pod support
- [x] 2 replicas configured
- [x] Pod anti-affinity enabled
- [x] PodDisruptionBudget configured
- ⚠️ **Requires NFS or cloud storage**

#### KIND Testing (owncloud-kind.yaml)
- [x] Uses ReadWriteOnce (KIND compatible)
- [x] 1 replica only
- [x] Compatible with local-path provisioner
- ✅ **Ready for KIND testing**

### 5. Resource Limits
- [x] ownCloud: 512Mi-1Gi RAM, 250m-1000m CPU
- [x] PostgreSQL: 2Gi RAM, 500m-1000m CPU
- [x] Redis: 128Mi-256Mi RAM, 100m-200m CPU

### 6. Health Probes
- [x] ownCloud: startup, liveness, readiness probes
- [x] PostgreSQL: liveness, readiness probes
- [x] Redis: liveness, readiness probes

### 7. Image Versions
- [x] ownCloud: 10.16 (latest stable before EOL)
- [x] PostgreSQL: 17 (latest stable)
- [x] Redis: 7.4 (latest LTS)

### 8. Configuration Values
- [x] Database type: pgsql
- [x] Database name: owncloud
- [x] Database username: owncloud
- [x] Database host: postgresql
- [x] Redis enabled: true
- [x] Redis host: redis

## 🔍 Manual Verification Steps

### Step 1: Validate YAML Syntax

```bash
# Validate all YAML files
for file in *.yaml; do
  echo "Validating $file..."
  kubectl apply --dry-run=client -f "$file" 2>&1 | grep -v "Warning"
done
```

### Step 2: Check Namespace Consistency

```bash
# Extract all namespaces from YAML files
grep -h "namespace:" *.yaml | sort | uniq

# Expected output (should all be owncloud-namespace):
# namespace: owncloud-namespace
```

### Step 3: Verify Secret References

```bash
# Check secret name in postgresql.yaml
grep -A2 "secretKeyRef:" postgresql.yaml

# Should show:
#   name: owncloud-secrets
#   key: OWNCLOUD_DB_PASSWORD
```

### Step 4: Verify Service Names

```bash
# Check service names match configmap references
grep "name: postgresql" postgresql.yaml
grep "name: redis" redis.yaml
grep "OWNCLOUD_DB_HOST" configmap.yaml
grep "OWNCLOUD_REDIS_HOST" configmap.yaml
```

## 🚀 Deployment Order

### For KIND Testing (Recommended)

```bash
# 1. Infrastructure
kubectl apply -f owncloud-namespace.yaml
kubectl apply -f storageclass-kind.yaml

# 2. Configuration
kubectl apply -f owncloud-secret.yaml
kubectl apply -f configmap.yaml

# 3. Data Layer
kubectl apply -f postgresql.yaml
kubectl apply -f redis.yaml

# Wait for data layer to be ready
kubectl wait --for=condition=ready pod -l app=postgresql -n owncloud-namespace --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n owncloud-namespace --timeout=300s

# 4. Application Layer
kubectl apply -f owncloud-kind.yaml

# Wait for application to be ready
kubectl wait --for=condition=ready pod -l app=owncloud -n owncloud-namespace --timeout=300s

# 5. Ingress (optional for KIND)
# kubectl apply -f owncloud-ingress.yaml
```

### For Production (with NFS/Cloud Storage)

```bash
# 1. Infrastructure
kubectl apply -f owncloud-namespace.yaml
kubectl apply -f storageclass.yaml  # Ensure this supports ReadWriteMany

# 2. Configuration
kubectl apply -f owncloud-secret.yaml
kubectl apply -f configmap.yaml

# 3. Data Layer
kubectl apply -f postgresql.yaml
kubectl apply -f redis.yaml

# Wait for data layer
kubectl wait --for=condition=ready pod -l app=postgresql -n owncloud-namespace --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n owncloud-namespace --timeout=300s

# 4. Application Layer (2 replicas with ReadWriteMany)
kubectl apply -f owncloud.yaml

# Wait for application
kubectl wait --for=condition=ready pod -l app=owncloud -n owncloud-namespace --timeout=300s

# 5. Ingress
kubectl apply -f owncloud-ingress.yaml
```

## 🧪 Post-Deployment Tests

### Test 1: All Pods Running

```bash
kubectl get pods -n owncloud-namespace

# Expected: All pods in Running state with READY 1/1
```

### Test 2: PVCs Bound

```bash
kubectl get pvc -n owncloud-namespace

# Expected: All PVCs in Bound state
```

### Test 3: Services Accessible

```bash
# Test PostgreSQL connectivity
kubectl run -it --rm debug --image=postgres:17 --restart=Never -n owncloud-namespace -- \
  psql -h postgresql -U owncloud -d owncloud -c "SELECT version();"

# Test Redis connectivity
kubectl run -it --rm debug --image=redis:7.4 --restart=Never -n owncloud-namespace -- \
  redis-cli -h redis ping

# Expected: PONG
```

### Test 4: ownCloud Accessible

```bash
# Port forward
kubectl port-forward -n owncloud-namespace svc/owncloud 8080:80

# Test in browser or curl
curl -I http://localhost:8080/status.php

# Expected: HTTP 200 OK
```

### Test 5: Database Connection

```bash
# Check ownCloud logs for database connection
kubectl logs -n owncloud-namespace -l app=owncloud --tail=100 | grep -i database

# Should not show connection errors
```

## ⚠️ Known Issues & Solutions

### Issue 1: PVC Pending in KIND
**Symptom**: PVC stuck in Pending state

**Solution**:
```bash
# Check if local-path provisioner is running
kubectl get pods -n local-path-storage

# If not, install it
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

### Issue 2: ReadWriteMany Not Supported in KIND
**Symptom**: PVC with ReadWriteMany won't bind

**Solution**: Use `owncloud-kind.yaml` instead of `owncloud.yaml` for KIND testing

### Issue 3: PostgreSQL Won't Start
**Symptom**: PostgreSQL pod in CrashLoopBackOff

**Solution**:
```bash
# Check logs
kubectl logs -n owncloud-namespace -l app=postgresql --tail=100

# Common fix: Delete PVC and recreate
kubectl delete pvc postgresql-pvc -n owncloud-namespace
kubectl apply -f postgresql.yaml
```

### Issue 4: ownCloud Can't Connect to Database
**Symptom**: ownCloud logs show database connection errors

**Solution**:
```bash
# Verify PostgreSQL is ready
kubectl get pods -n owncloud-namespace -l app=postgresql

# Check secret has correct password
kubectl get secret owncloud-secrets -n owncloud-namespace -o jsonpath='{.data.OWNCLOUD_DB_PASSWORD}' | base64 -d

# Restart ownCloud pod
kubectl delete pod -n owncloud-namespace -l app=owncloud
```

## 📊 Monitoring Commands

```bash
# Watch all pods
kubectl get pods -n owncloud-namespace -w

# Stream logs from all ownCloud pods
kubectl logs -n owncloud-namespace -l app=owncloud -f --all-containers=true

# Check events
kubectl get events -n owncloud-namespace --sort-by='.lastTimestamp' | tail -20

# Resource usage
kubectl top pods -n owncloud-namespace
```

## ✅ Final Checklist Before Production

- [ ] Changed default passwords in `owncloud-secret.yaml`
- [ ] Updated domain in `owncloud-ingress.yaml`
- [ ] Configured proper SSL/TLS certificates
- [ ] Set up ReadWriteMany storage (NFS/cloud)
- [ ] Adjusted resource limits based on load testing
- [ ] Configured backup strategy
- [ ] Set up monitoring and alerting
- [ ] Tested failover scenarios
- [ ] Documented disaster recovery procedures
- [ ] Reviewed security best practices

## 🎯 Ready for Testing!

All critical issues have been fixed:
- ✅ Namespace consistency
- ✅ Secret references corrected
- ✅ KIND-compatible configuration created
- ✅ Deployment guides prepared
- ✅ ArgoCD integration ready

You can now proceed with KIND and ArgoCD testing!
