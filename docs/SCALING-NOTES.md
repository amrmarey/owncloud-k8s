# ownCloud Scaling Configuration

## Overview
The ownCloud deployment has been configured to run with **at least 2 pods** following ownCloud's official deployment best practices for high availability.

## Changes Made

### 1. **Increased Replicas to 2**
- Changed `replicas: 1` to `replicas: 2` in the Deployment
- Provides high availability and load distribution
- Minimum recommended by ownCloud for production deployments

### 2. **Updated Storage Access Mode**
- Changed PVC access mode from `ReadWriteOnce` to `ReadWriteMany`
- **Critical**: This allows multiple pods to access the same storage simultaneously
- Required for horizontal scaling according to ownCloud documentation

### 3. **Added Pod Anti-Affinity**
- Configured `preferredDuringSchedulingIgnoredDuringExecution` pod anti-affinity
- Ensures pods are distributed across different nodes when possible
- Prevents single node failure from taking down all ownCloud instances
- Follows ownCloud's best practice: "Distributing ownCloud pods uniformly across different nodes is vital for high availability"

### 4. **Added Pod Disruption Budget (PDB)**
- Ensures at least 1 pod remains available during voluntary disruptions
- Protects against downtime during node maintenance or cluster upgrades
- Kubernetes best practice for production deployments

## ownCloud Best Practices Implemented

Based on [ownCloud's official deployment recommendations](https://doc.owncloud.com/server/admin_manual/installation/deployment_recommendations.html):

✅ **Multiple Application Servers**: 2 pods (minimum for HA)  
✅ **Shared Storage**: ReadWriteMany access mode  
✅ **Redis for Session Management**: Already configured in configmap.yaml  
✅ **Database**: PostgreSQL already configured  
✅ **Load Balancing**: Kubernetes Service provides built-in load balancing  
✅ **Health Probes**: Liveness, readiness, and startup probes configured  
✅ **Resource Limits**: CPU and memory limits defined  

## Important Storage Considerations

### Storage Class Requirements
Your current storage class (`owncloud-storage`) uses `kubernetes.io/no-provisioner`. For `ReadWriteMany` to work, you need:

**Option 1: NFS Storage (Recommended by ownCloud)**
- Set up an NFS server or use a cloud provider's NFS service
- Update the storage class to use an NFS provisioner
- Example: `nfs-client` or cloud-specific NFS provisioners

**Option 2: Cloud Provider Storage**
- **AWS**: EFS (Elastic File System)
- **Azure**: Azure Files
- **GCP**: Filestore

**Option 3: Distributed Storage**
- **Rook/Ceph**: ownCloud specifically mentions CephFS as suitable
- **GlusterFS**: Also supported by ownCloud

### If ReadWriteMany is Not Available
If you cannot provide ReadWriteMany storage:
1. Keep `replicas: 2` for high availability
2. Revert to `ReadWriteOnce` access mode
3. Only one pod will be active at a time (active-passive setup)
4. Kubernetes will automatically failover to the second pod if the first fails

## Deployment Commands

```bash
# Apply the updated configuration
kubectl apply -f owncloud.yaml

# Verify pods are running
kubectl get pods -n owncloud-namespace -l app=owncloud

# Check pod distribution across nodes
kubectl get pods -n owncloud-namespace -l app=owncloud -o wide

# Verify PVC is bound
kubectl get pvc -n owncloud-namespace files-pvc

# Check Pod Disruption Budget
kubectl get pdb -n owncloud-namespace
```

## Monitoring

```bash
# Watch pod status during deployment
kubectl get pods -n owncloud-namespace -l app=owncloud -w

# Check pod logs
kubectl logs -n owncloud-namespace -l app=owncloud --tail=50

# Describe deployment
kubectl describe deployment owncloud -n owncloud-namespace
```

## Troubleshooting

### Pods Stuck in Pending
- **Cause**: PVC cannot bind with ReadWriteMany mode
- **Solution**: Update storage class to support ReadWriteMany or revert to ReadWriteOnce

### Both Pods on Same Node
- **Cause**: Only one node available or insufficient resources
- **Solution**: This is okay - anti-affinity is "preferred" not "required"

### Pod Disruption Budget Blocking Drains
- **Cause**: Trying to drain a node but PDB requires 1 pod available
- **Solution**: This is working as intended - ensures high availability

## Next Steps

1. **Verify Storage**: Ensure your storage class supports ReadWriteMany
2. **Test Failover**: Delete one pod and verify the other continues serving traffic
3. **Monitor Performance**: Check if 2 pods handle your load adequately
4. **Consider Autoscaling**: Implement HPA (Horizontal Pod Autoscaler) for dynamic scaling based on CPU/memory

## References

- [ownCloud Deployment Recommendations](https://doc.owncloud.com/server/admin_manual/installation/deployment_recommendations.html)
- [ownCloud Kubernetes Guide](https://owncloud.com/news/running-owncloud-in-kubernetes/)
- [Kubernetes Pod Disruption Budgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
- [Kubernetes Pod Anti-Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)
