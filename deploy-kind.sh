#!/bin/bash
# Quick Start Script for KIND Deployment (Bash/WSL/Ubuntu)
# This script automates the deployment of ownCloud on KIND

set -e  # Exit on error

echo "🚀 ownCloud KIND Deployment Script"
echo "==================================="
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

if ! command_exists docker; then
    echo -e "${RED}❌ Docker is not installed or not in PATH${NC}"
    exit 1
fi

if ! command_exists kind; then
    echo -e "${RED}❌ KIND is not installed or not in PATH${NC}"
    echo -e "${YELLOW}   Install from: https://kind.sigs.k8s.io/docs/user/quick-start/#installation${NC}"
    exit 1
fi

if ! command_exists kubectl; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^owncloud$"; then
    echo -e "${YELLOW}⚠️  KIND cluster 'owncloud' already exists${NC}"
    read -p "Do you want to delete and recreate it? (y/N): " RESPONSE
    if [ "$RESPONSE" = "y" ] || [ "$RESPONSE" = "Y" ]; then
        echo -e "${YELLOW}🗑️  Deleting existing cluster...${NC}"
        kind delete cluster --name owncloud
    else
        echo -e "${GREEN}Using existing cluster...${NC}"
        kubectl cluster-info --context kind-owncloud
    fi
else
    # Create KIND cluster
    echo -e "${YELLOW}🔧 Creating KIND cluster with ingress support...${NC}"
    
    cat <<EOF | kind create cluster --name owncloud --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ KIND cluster created successfully${NC}"
    else
        echo -e "${RED}❌ Failed to create KIND cluster${NC}"
        exit 1
    fi
fi

echo ""

# Install nginx ingress controller
echo -e "${YELLOW}🌐 Installing nginx ingress controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo -e "${YELLOW}⏳ Waiting for ingress controller to be ready...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo -e "${GREEN}✅ Ingress controller ready${NC}"
echo ""

# Deploy ownCloud
echo -e "${YELLOW}📦 Deploying ownCloud stack...${NC}"

echo -e "${CYAN}  → Creating namespace...${NC}"
kubectl apply -f owncloud-namespace.yaml

echo -e "${CYAN}  → Creating storage class...${NC}"
kubectl apply -f storageclass-kind.yaml

echo -e "${CYAN}  → Creating secrets...${NC}"
kubectl apply -f owncloud-secret.yaml

echo -e "${CYAN}  → Creating ConfigMap...${NC}"
kubectl apply -f configmap.yaml

echo -e "${CYAN}  → Deploying PostgreSQL...${NC}"
kubectl apply -f postgresql.yaml

echo -e "${CYAN}  → Deploying Redis...${NC}"
kubectl apply -f redis.yaml

echo -e "${YELLOW}⏳ Waiting for database and cache to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=postgresql -n owncloud-namespace --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n owncloud-namespace --timeout=300s

echo -e "${GREEN}✅ Database and cache ready${NC}"

echo -e "${CYAN}  → Deploying ownCloud...${NC}"
kubectl apply -f owncloud-kind.yaml

echo -e "${YELLOW}⏳ Waiting for ownCloud to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=owncloud -n owncloud-namespace --timeout=300s

echo -e "${GREEN}✅ ownCloud deployed successfully!${NC}"
echo ""

# Display status
echo -e "${CYAN}📊 Deployment Status:${NC}"
echo "==================="
kubectl get pods -n owncloud-namespace
echo ""
kubectl get pvc -n owncloud-namespace
echo ""
kubectl get svc -n owncloud-namespace
echo ""

# Get NodePort
NODE_PORT=$(kubectl get svc owncloud -n owncloud-namespace -o jsonpath='{.spec.ports[0].nodePort}')

echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "======================"
echo ""
echo -e "${YELLOW}Access ownCloud at: http://localhost:$NODE_PORT${NC}"
echo ""
echo -e "${YELLOW}Or use port forwarding:${NC}"
echo -e "${CYAN}  kubectl port-forward -n owncloud-namespace svc/owncloud 8080:80${NC}"
echo "  Then access at: http://localhost:8080"
echo ""
echo -e "${YELLOW}Default credentials:${NC}"
echo -e "${CYAN}  Username: admin${NC}"
echo -e "${CYAN}  Password: admin${NC}"
echo ""
echo -e "${RED}⚠️  Remember to change the default password!${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "${CYAN}  View logs: kubectl logs -n owncloud-namespace -l app=owncloud --tail=50${NC}"
echo -e "${CYAN}  Watch pods: kubectl get pods -n owncloud-namespace -w${NC}"
echo -e "${CYAN}  Delete cluster: kind delete cluster --name owncloud${NC}"
echo ""
