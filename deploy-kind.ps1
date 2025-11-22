# Quick Start Script for KIND Deployment
# This script automates the deployment of ownCloud on KIND

Write-Host "🚀 ownCloud KIND Deployment Script" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if command exists
function Test-Command {
    param($Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

if (-not (Test-Command "docker")) {
    Write-Host "❌ Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

if (-not (Test-Command "kind")) {
    Write-Host "❌ KIND is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Install from: https://kind.sigs.k8s.io/docs/user/quick-start/#installation" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Command "kubectl")) {
    Write-Host "❌ kubectl is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "✅ All prerequisites met" -ForegroundColor Green
Write-Host ""

# Check if cluster already exists
$clusterExists = kind get clusters 2>$null | Select-String "owncloud"

if ($clusterExists) {
    Write-Host "⚠️  KIND cluster 'owncloud' already exists" -ForegroundColor Yellow
    $response = Read-Host "Do you want to delete and recreate it? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "🗑️  Deleting existing cluster..." -ForegroundColor Yellow
        kind delete cluster --name owncloud
    } else {
        Write-Host "Using existing cluster..." -ForegroundColor Green
        kubectl cluster-info --context kind-owncloud
    }
} else {
    # Create KIND cluster
    Write-Host "🔧 Creating KIND cluster with ingress support..." -ForegroundColor Yellow
    
    $kindConfig = @"
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
"@
    
    $kindConfig | kind create cluster --name owncloud --config=-
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to create KIND cluster" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ KIND cluster created successfully" -ForegroundColor Green
}

Write-Host ""

# Install nginx ingress controller
Write-Host "🌐 Installing nginx ingress controller..." -ForegroundColor Yellow
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

Write-Host "⏳ Waiting for ingress controller to be ready..." -ForegroundColor Yellow
kubectl wait --namespace ingress-nginx `
  --for=condition=ready pod `
  --selector=app.kubernetes.io/component=controller `
  --timeout=90s

Write-Host "✅ Ingress controller ready" -ForegroundColor Green
Write-Host ""

# Deploy ownCloud
Write-Host "📦 Deploying ownCloud stack..." -ForegroundColor Yellow

Write-Host "  → Creating namespace..." -ForegroundColor Cyan
kubectl apply -f owncloud-namespace.yaml

Write-Host "  → Creating storage class..." -ForegroundColor Cyan
kubectl apply -f storageclass-kind.yaml

Write-Host "  → Creating secrets..." -ForegroundColor Cyan
kubectl apply -f owncloud-secret.yaml

Write-Host "  → Creating ConfigMap..." -ForegroundColor Cyan
kubectl apply -f configmap.yaml

Write-Host "  → Deploying PostgreSQL..." -ForegroundColor Cyan
kubectl apply -f postgresql.yaml

Write-Host "  → Deploying Redis..." -ForegroundColor Cyan
kubectl apply -f redis.yaml

Write-Host "⏳ Waiting for database and cache to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=postgresql -n owncloud-namespace --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n owncloud-namespace --timeout=300s

Write-Host "✅ Database and cache ready" -ForegroundColor Green

Write-Host "  → Deploying ownCloud..." -ForegroundColor Cyan
kubectl apply -f owncloud-kind.yaml

Write-Host "⏳ Waiting for ownCloud to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=owncloud -n owncloud-namespace --timeout=300s

Write-Host "✅ ownCloud deployed successfully!" -ForegroundColor Green
Write-Host ""

# Display status
Write-Host "📊 Deployment Status:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
kubectl get pods -n owncloud-namespace
Write-Host ""
kubectl get pvc -n owncloud-namespace
Write-Host ""
kubectl get svc -n owncloud-namespace
Write-Host ""

# Get NodePort
$nodePort = kubectl get svc owncloud -n owncloud-namespace -o jsonpath='{.spec.ports[0].nodePort}'

Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green
Write-Host ""
Write-Host "Access ownCloud at: http://localhost:$nodePort" -ForegroundColor Yellow
Write-Host ""
Write-Host "Or use port forwarding:" -ForegroundColor Yellow
Write-Host "  kubectl port-forward -n owncloud-namespace svc/owncloud 8080:80" -ForegroundColor Cyan
Write-Host "  Then access at: http://localhost:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "Default credentials:" -ForegroundColor Yellow
Write-Host "  Username: admin" -ForegroundColor Cyan
Write-Host "  Password: admin" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  Remember to change the default password!" -ForegroundColor Red
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "  View logs: kubectl logs -n owncloud-namespace -l app=owncloud --tail=50" -ForegroundColor Cyan
Write-Host "  Watch pods: kubectl get pods -n owncloud-namespace -w" -ForegroundColor Cyan
Write-Host "  Delete cluster: kind delete cluster --name owncloud" -ForegroundColor Cyan
Write-Host ""
