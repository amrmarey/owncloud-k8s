#!/bin/bash
# Quick fix for PVC binding issues in KIND

set -e

echo "🔧 Fixing PVC Binding Issue in KIND"
echo "===================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. Check if local-path provisioner exists
echo -e "${YELLOW}📋 Checking for local-path provisioner...${NC}"
if kubectl get namespace local-path-storage >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Local-path provisioner namespace exists${NC}"
    
    if kubectl get pods -n local-path-storage | grep -q "Running"; then
        echo -e "${GREEN}✅ Local-path provisioner is running${NC}"
    else
        echo -e "${YELLOW}⚠️  Local-path provisioner exists but not running${NC}"
        echo -e "${YELLOW}   Reinstalling...${NC}"
        kubectl delete namespace local-path-storage 2>/dev/null || true
        sleep 5
    fi
else
    echo -e "${YELLOW}⚠️  Local-path provisioner not found${NC}"
fi

# 2. Install/Reinstall local-path provisioner
if ! kubectl get pods -n local-path-storage 2>/dev/null | grep -q "Running"; then
    echo -e "${YELLOW}📦 Installing local-path provisioner...${NC}"
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
    
    echo -e "${YELLOW}⏳ Waiting for provisioner to be ready...${NC}"
    kubectl wait --for=condition=ready pod -l app=local-path-provisioner -n local-path-storage --timeout=60s
    
    echo -e "${GREEN}✅ Local-path provisioner installed${NC}"
fi

echo ""

# 3. Verify storage class
echo -e "${YELLOW}📊 Checking storage classes...${NC}"
kubectl get storageclass

echo ""

# 4. Check current PVC status
echo -e "${YELLOW}📊 Current PVC status:${NC}"
kubectl get pvc -n owncloud-namespace 2>/dev/null || echo "No PVCs found yet"

echo ""

# 5. Check if PVCs are pending
PENDING_PVCS=$(kubectl get pvc -n owncloud-namespace 2>/dev/null | grep -c "Pending" || echo "0")

if [ "$PENDING_PVCS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found $PENDING_PVCS pending PVC(s)${NC}"
    echo -e "${YELLOW}🗑️  Deleting pending PVCs to trigger recreation...${NC}"
    
    kubectl delete pvc --all -n owncloud-namespace
    
    echo -e "${YELLOW}⏳ Waiting for ArgoCD to recreate PVCs...${NC}"
    sleep 10
    
    echo -e "${CYAN}📊 New PVC status:${NC}"
    kubectl get pvc -n owncloud-namespace 2>/dev/null || echo "Waiting for PVCs to be created..."
else
    echo -e "${GREEN}✅ No pending PVCs found${NC}"
fi

echo ""

# 6. Wait for PVCs to bind
echo -e "${YELLOW}⏳ Waiting for PVCs to bind (max 60 seconds)...${NC}"
TIMEOUT=60
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    BOUND_COUNT=$(kubectl get pvc -n owncloud-namespace 2>/dev/null | grep -c "Bound" || echo "0")
    TOTAL_COUNT=$(kubectl get pvc -n owncloud-namespace 2>/dev/null | grep -v "NAME" | wc -l || echo "0")
    
    if [ "$TOTAL_COUNT" -gt 0 ] && [ "$BOUND_COUNT" -eq "$TOTAL_COUNT" ]; then
        echo -e "${GREEN}✅ All PVCs are bound!${NC}"
        break
    fi
    
    echo -e "${CYAN}   Bound: $BOUND_COUNT/$TOTAL_COUNT${NC}"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

echo ""

# 7. Final status
echo -e "${CYAN}📊 Final Status:${NC}"
echo "==============="
echo ""

echo -e "${CYAN}Storage Classes:${NC}"
kubectl get storageclass

echo ""
echo -e "${CYAN}PVCs:${NC}"
kubectl get pvc -n owncloud-namespace 2>/dev/null || echo "No PVCs found"

echo ""
echo -e "${CYAN}Pods:${NC}"
kubectl get pods -n owncloud-namespace 2>/dev/null || echo "No pods found yet"

echo ""

# 8. Check if all PVCs are bound
ALL_BOUND=$(kubectl get pvc -n owncloud-namespace 2>/dev/null | grep -v "NAME" | grep -v "Bound" | wc -l || echo "1")

if [ "$ALL_BOUND" -eq 0 ]; then
    echo -e "${GREEN}🎉 Success! All PVCs are bound${NC}"
    echo -e "${GREEN}   Pods should start automatically now${NC}"
    echo ""
    echo -e "${YELLOW}📚 Monitor pod startup with:${NC}"
    echo -e "${CYAN}   kubectl get pods -n owncloud-namespace -w${NC}"
else
    echo -e "${RED}⚠️  Some PVCs are still not bound${NC}"
    echo ""
    echo -e "${YELLOW}📚 Troubleshooting:${NC}"
    echo -e "${CYAN}1. Check PVC details:${NC}"
    echo "   kubectl describe pvc -n owncloud-namespace"
    echo ""
    echo -e "${CYAN}2. Check provisioner logs:${NC}"
    echo "   kubectl logs -n local-path-storage -l app=local-path-provisioner"
    echo ""
    echo -e "${CYAN}3. Check storage class:${NC}"
    echo "   kubectl describe storageclass owncloud-storage"
fi

echo ""
