#!/bin/bash
# Comprehensive diagnostic script for PVC binding issues

echo "🔍 PVC Binding Diagnostic Tool"
echo "==============================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}1. Checking Kubernetes cluster...${NC}"
if kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Cluster is accessible${NC}"
else
    echo -e "${RED}❌ Cannot connect to cluster${NC}"
    exit 1
fi
echo ""

echo -e "${CYAN}2. Checking namespaces...${NC}"
kubectl get namespace owncloud-namespace 2>/dev/null || echo -e "${YELLOW}⚠️  owncloud-namespace not found${NC}"
kubectl get namespace local-path-storage 2>/dev/null || echo -e "${YELLOW}⚠️  local-path-storage not found${NC}"
echo ""

echo -e "${CYAN}3. Checking local-path provisioner...${NC}"
if kubectl get namespace local-path-storage >/dev/null 2>&1; then
    kubectl get pods -n local-path-storage
    echo ""
    echo -e "${CYAN}Provisioner logs (last 20 lines):${NC}"
    kubectl logs -n local-path-storage -l app=local-path-provisioner --tail=20 2>/dev/null || echo "No logs available"
else
    echo -e "${RED}❌ local-path-storage namespace not found${NC}"
    echo -e "${YELLOW}   Run: kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml${NC}"
fi
echo ""

echo -e "${CYAN}4. Checking storage classes...${NC}"
kubectl get storageclass
echo ""
echo -e "${CYAN}Storage class details:${NC}"
kubectl get storageclass owncloud-storage -o yaml 2>/dev/null || echo -e "${YELLOW}⚠️  owncloud-storage not found${NC}"
echo ""

echo -e "${CYAN}5. Checking PVCs...${NC}"
kubectl get pvc -n owncloud-namespace 2>/dev/null || echo -e "${YELLOW}⚠️  No PVCs found in owncloud-namespace${NC}"
echo ""

echo -e "${CYAN}6. Detailed PVC information...${NC}"
for pvc in $(kubectl get pvc -n owncloud-namespace -o name 2>/dev/null); do
    echo -e "${YELLOW}Describing $pvc:${NC}"
    kubectl describe $pvc -n owncloud-namespace | grep -A 10 "Events:"
    echo ""
done

echo -e "${CYAN}7. Checking PVs...${NC}"
kubectl get pv
echo ""

echo -e "${CYAN}8. Checking pods...${NC}"
kubectl get pods -n owncloud-namespace 2>/dev/null || echo -e "${YELLOW}⚠️  No pods found${NC}"
echo ""

echo -e "${CYAN}9. Checking ArgoCD application...${NC}"
kubectl get application owncloud -n argocd 2>/dev/null || echo -e "${YELLOW}⚠️  ArgoCD application not found${NC}"
echo ""

echo -e "${CYAN}10. Node information...${NC}"
kubectl get nodes
echo ""
kubectl describe node | grep -A 5 "Allocated resources:" || true
echo ""

echo "================================"
echo -e "${CYAN}Diagnostic Summary:${NC}"
echo "================================"
echo ""

# Check if provisioner is running
if kubectl get pods -n local-path-storage 2>/dev/null | grep -q "Running"; then
    echo -e "${GREEN}✅ Local-path provisioner is running${NC}"
else
    echo -e "${RED}❌ Local-path provisioner is NOT running${NC}"
    echo -e "${YELLOW}   Fix: kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml${NC}"
fi

# Check if storage class exists
if kubectl get storageclass owncloud-storage >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Storage class 'owncloud-storage' exists${NC}"
    
    # Check provisioner name
    PROVISIONER=$(kubectl get storageclass owncloud-storage -o jsonpath='{.provisioner}')
    echo -e "${CYAN}   Provisioner: $PROVISIONER${NC}"
    
    if [ "$PROVISIONER" != "rancher.io/local-path" ]; then
        echo -e "${RED}   ⚠️  Provisioner mismatch! Expected: rancher.io/local-path${NC}"
    fi
else
    echo -e "${RED}❌ Storage class 'owncloud-storage' NOT found${NC}"
fi

# Check PVC status
PENDING_PVCS=$(kubectl get pvc -n owncloud-namespace 2>/dev/null | grep -c "Pending" || echo "0")
BOUND_PVCS=$(kubectl get pvc -n owncloud-namespace 2>/dev/null | grep -c "Bound" || echo "0")
TOTAL_PVCS=$(kubectl get pvc -n owncloud-namespace 2>/dev/null | grep -v "NAME" | wc -l || echo "0")

if [ "$TOTAL_PVCS" -gt 0 ]; then
    echo -e "${CYAN}PVC Status: $BOUND_PVCS Bound, $PENDING_PVCS Pending (Total: $TOTAL_PVCS)${NC}"
    
    if [ "$PENDING_PVCS" -gt 0 ]; then
        echo -e "${RED}❌ Some PVCs are still pending${NC}"
    else
        echo -e "${GREEN}✅ All PVCs are bound${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No PVCs found${NC}"
fi

echo ""
echo "================================"
echo -e "${YELLOW}Recommended Actions:${NC}"
echo "================================"

if ! kubectl get pods -n local-path-storage 2>/dev/null | grep -q "Running"; then
    echo -e "${CYAN}1. Install local-path provisioner:${NC}"
    echo "   kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml"
    echo ""
fi

if [ "$PENDING_PVCS" -gt 0 ]; then
    echo -e "${CYAN}2. Delete and recreate pending PVCs:${NC}"
    echo "   kubectl delete pvc --all -n owncloud-namespace"
    echo "   kubectl delete application owncloud -n argocd"
    echo "   kubectl apply -f kind/docs-and-tools/argocd-application-kind.yaml"
    echo ""
fi

echo -e "${CYAN}3. Monitor PVC binding:${NC}"
echo "   kubectl get pvc -n owncloud-namespace -w"
echo ""

echo "================================"
