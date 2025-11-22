# ArgoCD Deployment Script for ownCloud
# This script automates the deployment of ownCloud using ArgoCD

Write-Host "🔄 ownCloud ArgoCD Deployment Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if command exists
function Test-Command {
    param($Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

if (-not (Test-Command "kubectl")) {
    Write-Host "❌ kubectl is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "✅ kubectl found" -ForegroundColor Green

# Check if cluster is accessible
try {
    kubectl cluster-info | Out-Null
    Write-Host "✅ Kubernetes cluster accessible" -ForegroundColor Green
}
catch {
    Write-Host "❌ Cannot connect to Kubernetes cluster" -ForegroundColor Red
    Write-Host "   Make sure your cluster is running (e.g., KIND cluster)" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Check if ArgoCD is already installed
$argoCDNamespace = kubectl get namespace argocd --ignore-not-found -o name 2>$null

if (-not $argoCDNamespace) {
    Write-Host "📦 ArgoCD not found. Installing ArgoCD..." -ForegroundColor Yellow
    
    # Create ArgoCD namespace
    Write-Host "  → Creating argocd namespace..." -ForegroundColor Cyan
    kubectl create namespace argocd
    
    # Install ArgoCD
    Write-Host "  → Installing ArgoCD components..." -ForegroundColor Cyan
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    Write-Host "⏳ Waiting for ArgoCD to be ready (this may take 2-3 minutes)..." -ForegroundColor Yellow
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
    
    Write-Host "✅ ArgoCD installed successfully" -ForegroundColor Green
}
else {
    Write-Host "✅ ArgoCD already installed" -ForegroundColor Green
}

Write-Host ""

# Get ArgoCD admin password
Write-Host "🔑 Retrieving ArgoCD admin password..." -ForegroundColor Yellow
$argoCDPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

if ($argoCDPassword) {
    Write-Host "✅ ArgoCD admin password retrieved" -ForegroundColor Green
}
else {
    Write-Host "⚠️  Could not retrieve ArgoCD password (may have been changed)" -ForegroundColor Yellow
}

Write-Host ""

# Ask user which deployment mode
Write-Host "📂 Select deployment mode:" -ForegroundColor Cyan
Write-Host "  1. KIND/Local testing (uses owncloud-kind.yaml, 1 replica)" -ForegroundColor White
Write-Host "  2. Production (uses owncloud.yaml, 2 replicas, requires ReadWriteMany storage)" -ForegroundColor White
Write-Host ""
$deployMode = Read-Host "Enter choice (1 or 2)"

if ($deployMode -eq "1") {
    Write-Host "📦 Deploying for KIND/Local testing..." -ForegroundColor Yellow
    $useKindFiles = $true
}
elseif ($deployMode -eq "2") {
    Write-Host "🏭 Deploying for Production..." -ForegroundColor Yellow
    $useKindFiles = $false
}
else {
    Write-Host "❌ Invalid choice. Defaulting to KIND/Local testing..." -ForegroundColor Red
    $useKindFiles = $true
}

Write-Host ""

# Create or update ArgoCD application based on mode
if ($useKindFiles) {
    # Create ArgoCD application for KIND
    Write-Host "📝 Creating ArgoCD Application for KIND testing..." -ForegroundColor Yellow
    
    $argoCDApp = @"
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
      # Include only KIND-compatible files
      include: |
        owncloud-namespace.yaml
        storageclass-kind.yaml
        owncloud-secret.yaml
        configmap.yaml
        postgresql.yaml
        redis.yaml
        owncloud-kind.yaml
  
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
"@
}
else {
    # Create ArgoCD application for Production
    Write-Host "📝 Creating ArgoCD Application for Production..." -ForegroundColor Yellow
    
    $argoCDApp = @"
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
      # Exclude KIND-specific and documentation files
      exclude: |
        *-kind.yaml
        *.md
        .git/**
        mariadb.yaml.backup
        deploy-kind.ps1
  
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
"@
}

# Save and apply the application
$argoCDApp | Out-File -FilePath "argocd-app-temp.yaml" -Encoding UTF8

Write-Host "🚀 Deploying ArgoCD Application..." -ForegroundColor Yellow
kubectl apply -f argocd-app-temp.yaml

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ ArgoCD Application created successfully" -ForegroundColor Green
}
else {
    Write-Host "❌ Failed to create ArgoCD Application" -ForegroundColor Red
    Remove-Item "argocd-app-temp.yaml" -ErrorAction SilentlyContinue
    exit 1
}

# Clean up temp file
Remove-Item "argocd-app-temp.yaml" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "⏳ Waiting for initial sync to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check application status
Write-Host "📊 Application Status:" -ForegroundColor Cyan
kubectl get application owncloud -n argocd

Write-Host ""
Write-Host "⏳ Waiting for resources to be created (this may take a few minutes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Wait for pods to be ready
Write-Host "⏳ Waiting for pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=postgresql -n owncloud-namespace --timeout=300s 2>$null
kubectl wait --for=condition=ready pod -l app=redis -n owncloud-namespace --timeout=300s 2>$null
kubectl wait --for=condition=ready pod -l app=owncloud -n owncloud-namespace --timeout=300s 2>$null

Write-Host ""
Write-Host "📊 Deployment Status:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
kubectl get pods -n owncloud-namespace
Write-Host ""
kubectl get pvc -n owncloud-namespace
Write-Host ""
kubectl get svc -n owncloud-namespace

Write-Host ""
Write-Host "🎉 ArgoCD Deployment Complete!" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""

# Display access information
Write-Host "🌐 Access ArgoCD UI:" -ForegroundColor Yellow
Write-Host "  1. Port forward ArgoCD server:" -ForegroundColor Cyan
Write-Host "     kubectl port-forward svc/argocd-server -n argocd 8081:443" -ForegroundColor White
Write-Host ""
Write-Host "  2. Access at: https://localhost:8081" -ForegroundColor Cyan
Write-Host "     Username: admin" -ForegroundColor White
if ($argoCDPassword) {
    Write-Host "     Password: $argoCDPassword" -ForegroundColor White
}
else {
    Write-Host "     Password: (retrieve with: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=`"{.data.password}`" | base64 -d)" -ForegroundColor White
}

Write-Host ""
Write-Host "🌐 Access ownCloud:" -ForegroundColor Yellow

if ($useKindFiles) {
    $nodePort = kubectl get svc owncloud -n owncloud-namespace -o jsonpath='{.spec.ports[0].nodePort}' 2>$null
    if ($nodePort) {
        Write-Host "  NodePort: http://localhost:$nodePort" -ForegroundColor Cyan
    }
}

Write-Host "  Port forward: kubectl port-forward -n owncloud-namespace svc/owncloud 8080:80" -ForegroundColor Cyan
Write-Host "  Then access at: http://localhost:8080" -ForegroundColor White
Write-Host ""
Write-Host "  Default credentials:" -ForegroundColor White
Write-Host "    Username: admin" -ForegroundColor Cyan
Write-Host "    Password: admin" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  Remember to change the default password!" -ForegroundColor Red

Write-Host ""
Write-Host "📚 Useful Commands:" -ForegroundColor Yellow
Write-Host "  View ArgoCD app status: kubectl get application owncloud -n argocd" -ForegroundColor Cyan
Write-Host "  View app details: kubectl describe application owncloud -n argocd" -ForegroundColor Cyan
Write-Host "  View pods: kubectl get pods -n owncloud-namespace" -ForegroundColor Cyan
Write-Host "  View logs: kubectl logs -n owncloud-namespace -l app=owncloud --tail=50" -ForegroundColor Cyan
Write-Host "  Delete app: kubectl delete application owncloud -n argocd" -ForegroundColor Cyan
Write-Host ""
