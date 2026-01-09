param(
    [string]$Environment = "all"
)

Write-Host "Deploiement Online Boutique GitOps" -ForegroundColor Green
Write-Host "Environnement: $Environment" -ForegroundColor Yellow

# Verification des prerequis
Write-Host "Verification des prerequis..." -ForegroundColor Blue

if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "ERREUR: kubectl n'est pas installe" -ForegroundColor Red
    exit 1
}

try {
    kubectl cluster-info | Out-Null
    Write-Host "Prerequis OK" -ForegroundColor Green
}
catch {
    Write-Host "ERREUR: Pas de connexion au cluster Kubernetes" -ForegroundColor Red
    exit 1
}

# Deploiement
if ($Environment -eq "dev" -or $Environment -eq "all") {
    Write-Host "Deploiement environnement DEV..." -ForegroundColor Blue
    kubectl apply -k argocd/dev
    Write-Host "Applications DEV deployees" -ForegroundColor Green
}

if ($Environment -eq "prod" -or $Environment -eq "all") {
    Write-Host "Deploiement environnement PROD..." -ForegroundColor Blue
    kubectl apply -k argocd/prod
    Write-Host "Applications PROD deployees" -ForegroundColor Green
}

# Verification
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "Applications ArgoCD:" -ForegroundColor Yellow
kubectl get applications -n argocd

Write-Host ""
Write-Host "Deploiement termine!" -ForegroundColor Green
Write-Host ""
Write-Host "Pour acceder a l'application:" -ForegroundColor Yellow
Write-Host "  Dev:  kubectl port-forward -n online-boutique-dev svc/frontend-online-boutique-service 8080:8080"
Write-Host "  Prod: kubectl port-forward -n online-boutique-prod svc/frontend-online-boutique-service 8081:8080"
Write-Host ""
Write-Host "Pour acceder a ArgoCD:" -ForegroundColor Yellow
Write-Host "  kubectl port-forward svc/argocd-server -n argocd 8082:443"
Write-Host "  URL: https://localhost:8082"
Write-Host "  Username: admin"
Write-Host "  Password: 3H-sejo-MRftTQTu"