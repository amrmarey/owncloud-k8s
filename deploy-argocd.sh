#!/bin/bash
# ArgoCD Deployment Script for ownCloud (Bash/WSL/Ubuntu)
# This script automates the deployment of ownCloud using ArgoCD

set -e  # Exit on error

echo "🔄 ownCloud ArgoCD Deployment Script"
echo "====================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command_exists kubectl; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ kubectl found${NC}"

# Check if cluster is accessible
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
    echo -e "${YELLOW}   Make sure your cluster is running (e.g., KIND cluster)${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Kubernetes cluster accessible${NC}"
echo ""

# Check if ArgoCD is already installed
if kubectl get namespace argocd >/dev/null 2>&1; then
    echo -e "${GREEN}✅ ArgoCD already installed${NC}"
else
    echo -e "${YELLOW}📦 ArgoCD not found. Installing ArgoCD...${NC}"
    
    # Create ArgoCD namespace
    echo -e "${CYAN}  → Creating argocd namespace...${NC}"
    kubectl create namespace argocd
    
    # Install ArgoCD
    echo -e "${CYAN}  → Installing ArgoCD components...${NC}"
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo -e "${YELLOW}⏳ Waiting for ArgoCD to be ready (this may take 2-3 minutes)...${NC}"
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
    
    echo -e "${GREEN}✅ ArgoCD installed successfully${NC}"
fi

echo ""

# Get ArgoCD admin password
echo -e "${YELLOW}🔑 Retrieving ArgoCD admin password...${NC}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)

if [ -n "$ARGOCD_PASSWORD" ]; then
    echo -e "${GREEN}✅ ArgoCD admin password retrieved${NC}"
else
    echo -e "${YELLOW}⚠️  Could not retrieve ArgoCD password (may have been changed)${NC}"
fi

echo ""

# Ask user which deployment mode
echo -e "${CYAN}📂 Select deployment mode:${NC}"
echo "  1. KIND/Local testing (uses owncloud-kind.yaml, 1 replica)"
echo "  2. Production (uses owncloud.yaml, 2 replicas, requires ReadWriteMany storage)"
echo ""
read -p "Enter choice (1 or 2): " DEPLOY_MODE

if [ "$DEPLOY_MODE" = "1" ]; then
    echo -e "${YELLOW}📦 Deploying for KIND/Local testing...${NC}"
    USE_KIND_FILES=true
elif [ "$DEPLOY_MODE" = "2" ]; then
    echo -e "${YELLOW}🏭 Deploying for Production...${NC}"
    USE_KIND_FILES=false
else
    echo -e "${RED}❌ Invalid choice. Defaulting to KIND/Local testing...${NC}"
    USE_KIND_FILES=true
fi

echo ""

# Create or update ArgoCD application based on mode
if [ "$USE_KIND_FILES" = true ]; then
    # Create ArgoCD application for KIND
    echo -e "${YELLOW}📝 Creating ArgoCD Application for KIND testing...${NC}"
    
    cat > argocd-app-temp.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: owncloud
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  
  source:
    repoURL: https://github.com/amrmarey/owncloud-k8s.git
    targetRevision: HEAD
    path: kind
  
  destination:
    server: https://kubernetes.default.svc
    namespace: owncloud-namespace
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF
else
    # Create ArgoCD application for Production
    echo -e "${YELLOW}📝 Creating ArgoCD Application for Production...${NC}"
    
    cat > argocd-app-temp.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: owncloud
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  
  source:
    repoURL: https://github.com/amrmarey/owncloud-k8s.git
    targetRevision: HEAD
    path: .
    
    directory:
      recurse: false
      exclude: |
        *-kind.yaml
        *.md
        .git/**
        mariadb.yaml.backup
        deploy-kind.sh
        deploy-argocd.sh
  
  destination:
    server: https://kubernetes.default.svc
    namespace: owncloud-namespace
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas
EOF
fi

# Apply the application
echo -e "${YELLOW}🚀 Deploying ArgoCD Application...${NC}"
kubectl apply -f argocd-app-temp.yaml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ ArgoCD Application created successfully${NC}"
else
    echo -e "${RED}❌ Failed to create ArgoCD Application${NC}"
    rm -f argocd-app-temp.yaml
    exit 1
fi

# Clean up temp file
rm -f argocd-app-temp.yaml

echo ""
echo -e "${YELLOW}⏳ Waiting for initial sync to complete...${NC}"
sleep 5

# Check application status
echo -e "${CYAN}📊 Application Status:${NC}"
kubectl get application owncloud -n argocd

echo ""
echo -e "${YELLOW}⏳ Waiting for resources to be created (this may take a few minutes)...${NC}"
sleep 10

# Wait for pods to be ready
echo -e "${YELLOW}⏳ Waiting for pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=postgresql -n owncloud-namespace --timeout=300s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=redis -n owncloud-namespace --timeout=300s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=owncloud -n owncloud-namespace --timeout=300s 2>/dev/null || true

echo ""
echo -e "${CYAN}📊 Deployment Status:${NC}"
echo "==================="
kubectl get pods -n owncloud-namespace
echo ""
kubectl get pvc -n owncloud-namespace
echo ""
kubectl get svc -n owncloud-namespace

echo ""
echo -e "${GREEN}🎉 ArgoCD Deployment Complete!${NC}"
echo "=============================="
echo ""

# Display access information
echo -e "${YELLOW}🌐 Access ArgoCD UI:${NC}"
echo -e "${CYAN}  1. Port forward ArgoCD server:${NC}"
echo "     kubectl port-forward svc/argocd-server -n argocd 8081:443"
echo ""
echo -e "${CYAN}  2. Access at: https://localhost:8081${NC}"
echo "     Username: admin"
if [ -n "$ARGOCD_PASSWORD" ]; then
    echo "     Password: $ARGOCD_PASSWORD"
else
    echo "     Password: (retrieve with: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d)"
fi

echo ""
echo -e "${YELLOW}🌐 Access ownCloud:${NC}"

if [ "$USE_KIND_FILES" = true ]; then
    NODE_PORT=$(kubectl get svc owncloud -n owncloud-namespace -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    if [ -n "$NODE_PORT" ]; then
        echo -e "${CYAN}  NodePort: http://localhost:$NODE_PORT${NC}"
    fi
fi

echo -e "${CYAN}  Port forward: kubectl port-forward -n owncloud-namespace svc/owncloud 8080:80${NC}"
echo "  Then access at: http://localhost:8080"
echo ""
echo "  Default credentials:"
echo -e "${CYAN}    Username: admin${NC}"
echo -e "${CYAN}    Password: admin${NC}"
echo ""
echo -e "${RED}⚠️  Remember to change the default password!${NC}"

echo ""
echo -e "${YELLOW}📚 Useful Commands:${NC}"
echo -e "${CYAN}  View ArgoCD app status: kubectl get application owncloud -n argocd${NC}"
echo -e "${CYAN}  View app details: kubectl describe application owncloud -n argocd${NC}"
echo -e "${CYAN}  View pods: kubectl get pods -n owncloud-namespace${NC}"
echo -e "${CYAN}  View logs: kubectl logs -n owncloud-namespace -l app=owncloud --tail=50${NC}"
echo -e "${CYAN}  Delete app: kubectl delete application owncloud -n argocd${NC}"
echo ""
