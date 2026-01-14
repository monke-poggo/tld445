# Script PowerShell complet pour deployer Online Boutique avec Kind
# Auteur: Victor Poggi
# Date: Janvier 2026

param(
    [switch]$SkipClusterCreation,
    [switch]$SkipIngress,
    [switch]$SkipArgoCD,
    [string]$Environment = "all"
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Online Boutique - Setup Complet" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Fonction pour verifier les prerequis
function Test-Prerequisites {
    Write-Host "[*] Verification des prerequis..." -ForegroundColor Yellow
    
    # Verifier Docker
    try {
        docker version | Out-Null
        Write-Host "  [OK] Docker installe" -ForegroundColor Green
    }
    catch {
        Write-Host "  [X] Docker n'est pas installe ou n'est pas demarre" -ForegroundColor Red
        Write-Host "     Installez Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        exit 1
    }
    
    # Verifier Kind
    try {
        kind version | Out-Null
        Write-Host "  [OK] Kind installe" -ForegroundColor Green
    }
    catch {
        Write-Host "  [X] Kind n'est pas installe" -ForegroundColor Red
        Write-Host "     Installez Kind: choco install kind" -ForegroundColor Yellow
        Write-Host "     Ou telechargez depuis: https://kind.sigs.k8s.io/docs/user/quick-start/" -ForegroundColor Yellow
        exit 1
    }
    
    # Verifier kubectl
    try {
        kubectl version --client | Out-Null
        Write-Host "  [OK] kubectl installe" -ForegroundColor Green
    }
    catch {
        Write-Host "  [X] kubectl n'est pas installe" -ForegroundColor Red
        Write-Host "     Installez kubectl: choco install kubernetes-cli" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host ""
}

# Fonction pour creer le cluster Kind
function New-KindCluster {
    Write-Host "[*] Creation du cluster Kind..." -ForegroundColor Yellow
    
    # Verifier si le cluster existe deja
    $existingCluster = $null
    try {
        $existingCluster = kind get clusters 2>$null | Where-Object { $_ -eq "esiea-lab" }
    }
    catch {
        # Pas de cluster existant, c'est normal
    }
    
    if ($existingCluster) {
        Write-Host "  [!] Le cluster 'esiea-lab' existe deja" -ForegroundColor Yellow
        $response = Read-Host "  Voulez-vous le supprimer et le recreer? (o/N)"
        
        if ($response -eq "o" -or $response -eq "O") {
            Write-Host "  [*] Suppression du cluster existant..." -ForegroundColor Yellow
            kind delete cluster --name esiea-lab
            Write-Host "  [OK] Cluster supprime" -ForegroundColor Green
        }
        else {
            Write-Host "  [i] Utilisation du cluster existant" -ForegroundColor Cyan
            return
        }
    }
    
    # Creer le cluster
    Write-Host "  [*] Creation du cluster avec 3 noeuds (1 control-plane + 2 workers)..." -ForegroundColor Cyan
    kind create cluster --name esiea-lab --config kind-config.yaml
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Cluster cree avec succes" -ForegroundColor Green
    }
    else {
        Write-Host "  [X] Erreur lors de la creation du cluster" -ForegroundColor Red
        throw "Erreur creation cluster"
    }
    
    # Verifier le cluster
    Write-Host "  [*] Verification du cluster..." -ForegroundColor Cyan
    kubectl cluster-info --context kind-esiea-lab
    
    Write-Host ""
    Write-Host "  [*] Noeuds du cluster:" -ForegroundColor Cyan
    kubectl get nodes -o wide
    Write-Host ""
}

# Fonction pour installer l'Ingress NGINX
function Install-IngressNginx {
    Write-Host "[*] Installation de l'Ingress NGINX..." -ForegroundColor Yellow
    
    # Verifier si deja installe
    $existingIngress = kubectl get namespace ingress-nginx 2>$null
    
    if ($LASTEXITCODE -eq 0 -and $existingIngress) {
        Write-Host "  [i] Ingress NGINX deja installe" -ForegroundColor Cyan
    }
    else {
        Write-Host "  [*] Telechargement et installation..." -ForegroundColor Cyan
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Ingress NGINX installe" -ForegroundColor Green
        }
        else {
            Write-Host "  [X] Erreur lors de l'installation de l'Ingress" -ForegroundColor Red
            exit 1
        }
    }
    
    # Attendre que l'Ingress soit pret
    Write-Host "  [*] Attente que l'Ingress soit pret (max 90s)..." -ForegroundColor Cyan
    Start-Sleep -Seconds 10
    
    kubectl wait --namespace ingress-nginx `
        --for=condition=ready pod `
        --selector=app.kubernetes.io/component=controller `
        --timeout=90s 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Ingress NGINX pret" -ForegroundColor Green
    }
    else {
        Write-Host "  [!] Timeout - L'Ingress peut ne pas etre completement pret" -ForegroundColor Yellow
        Write-Host "  [i] Verification des pods..." -ForegroundColor Cyan
        kubectl get pods -n ingress-nginx
    }
    
    Write-Host ""
    Write-Host "  [*] Pods Ingress NGINX:" -ForegroundColor Cyan
    kubectl get pods -n ingress-nginx
    Write-Host ""
}

# Fonction pour installer ArgoCD
function Install-ArgoCD {
    Write-Host "[*] Installation d'ArgoCD..." -ForegroundColor Yellow
    
    # Verifier si deja installe
    $existingArgoCD = kubectl get namespace argocd 2>$null
    
    if ($LASTEXITCODE -eq 0 -and $existingArgoCD) {
        Write-Host "  [i] ArgoCD deja installe" -ForegroundColor Cyan
    }
    else {
        Write-Host "  [*] Creation du namespace argocd..." -ForegroundColor Cyan
        kubectl create namespace argocd
        
        Write-Host "  [*] Installation d'ArgoCD..." -ForegroundColor Cyan
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] ArgoCD installe" -ForegroundColor Green
        }
        else {
            Write-Host "  [X] Erreur lors de l'installation d'ArgoCD" -ForegroundColor Red
            exit 1
        }
    }
    
    # Attendre qu'ArgoCD soit pret
    Write-Host "  [*] Attente qu'ArgoCD soit pret (max 300s)..." -ForegroundColor Cyan
    Start-Sleep -Seconds 15
    
    kubectl wait --namespace argocd `
        --for=condition=ready pod `
        --selector=app.kubernetes.io/name=argocd-server `
        --timeout=300s 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] ArgoCD pret" -ForegroundColor Green
    }
    else {
        Write-Host "  [!] ArgoCD peut ne pas etre completement pret, mais on continue..." -ForegroundColor Yellow
    }
    
    # Recuperer le mot de passe admin
    Write-Host ""
    Write-Host "  [*] Recuperation du mot de passe ArgoCD..." -ForegroundColor Cyan
    Start-Sleep -Seconds 5
    
    try {
        $argoPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
        if ($argoPassword) {
            $decodedPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($argoPassword))
            Write-Host "  [OK] Mot de passe ArgoCD: $decodedPassword" -ForegroundColor Green
            Write-Host "     Username: admin" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "  [!] Impossible de recuperer le mot de passe pour le moment" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "  [*] Pods ArgoCD:" -ForegroundColor Cyan
    kubectl get pods -n argocd
    Write-Host ""
}

# Fonction pour deployer les applications
function Deploy-Applications {
    param([string]$Env)
    
    Write-Host "[*] Deploiement des applications $Env..." -ForegroundColor Yellow
    
    if ($Env -eq "dev" -or $Env -eq "all") {
        Write-Host "  [*] Deploiement environnement DEV..." -ForegroundColor Cyan
        kubectl apply -k argocd/dev
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Applications DEV deployees" -ForegroundColor Green
        }
        else {
            Write-Host "  [X] Erreur lors du deploiement DEV" -ForegroundColor Red
        }
    }
    
    if ($Env -eq "prod" -or $Env -eq "all") {
        Write-Host "  [*] Deploiement environnement PROD..." -ForegroundColor Cyan
        kubectl apply -k argocd/prod
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Applications PROD deployees" -ForegroundColor Green
        }
        else {
            Write-Host "  [X] Erreur lors du deploiement PROD" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "  [*] Attente de la synchronisation ArgoCD (30s)..." -ForegroundColor Cyan
    Start-Sleep -Seconds 30
    
    Write-Host ""
    Write-Host "  [*] Applications ArgoCD:" -ForegroundColor Cyan
    kubectl get applications -n argocd
    Write-Host ""
}

# Fonction pour afficher le statut
function Show-Status {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Statut du Deploiement" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "[*] Applications ArgoCD:" -ForegroundColor Yellow
    kubectl get applications -n argocd
    Write-Host ""
    
    if ($Environment -eq "dev" -or $Environment -eq "all") {
        Write-Host "[*] Pods DEV:" -ForegroundColor Yellow
        kubectl get pods -n online-boutique-dev 2>$null
        Write-Host ""
    }
    
    if ($Environment -eq "prod" -or $Environment -eq "all") {
        Write-Host "[*] Pods PROD:" -ForegroundColor Yellow
        kubectl get pods -n online-boutique-prod 2>$null
        Write-Host ""
        
        Write-Host "[*] HPA PROD:" -ForegroundColor Yellow
        kubectl get hpa -n online-boutique-prod 2>$null
        Write-Host ""
    }
}

# Fonction pour afficher les informations d'acces
function Show-AccessInfo {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Informations d'Acces" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "[*] Frontend Online Boutique:" -ForegroundColor Yellow
    Write-Host ""
    
    if ($Environment -eq "dev" -or $Environment -eq "all") {
        Write-Host "  DEV:" -ForegroundColor Cyan
        Write-Host "     Via Ingress: http://localhost" -ForegroundColor Green
        Write-Host "     Via Script:  .\open-frontend.ps1 dev" -ForegroundColor Green
        Write-Host ""
    }
    
    if ($Environment -eq "prod" -or $Environment -eq "all") {
        Write-Host "  PROD:" -ForegroundColor Cyan
        Write-Host "     Via Ingress: http://localhost/prod" -ForegroundColor Green
        Write-Host "     Via Script:  .\open-frontend.ps1 prod" -ForegroundColor Green
        Write-Host ""
    }
    
    Write-Host "[*] ArgoCD UI:" -ForegroundColor Yellow
    Write-Host "     Port-forward: kubectl port-forward svc/argocd-server -n argocd 8082:443" -ForegroundColor Cyan
    Write-Host "     URL: https://localhost:8082" -ForegroundColor Green
    Write-Host "     Username: admin" -ForegroundColor Cyan
    
    try {
        $argoPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
        if ($argoPassword) {
            $decodedPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($argoPassword))
            Write-Host "     Password: $decodedPassword" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "     Password: (recuperer avec la commande ci-dessus)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# Script principal
try {
    # Verifier les prerequis
    Test-Prerequisites
    
    # Creer le cluster Kind
    if (-not $SkipClusterCreation) {
        New-KindCluster
    }
    else {
        Write-Host "[i] Creation du cluster ignoree" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Installer l'Ingress NGINX
    if (-not $SkipIngress) {
        Install-IngressNginx
    }
    else {
        Write-Host "[i] Installation de l'Ingress ignoree" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Installer ArgoCD
    if (-not $SkipArgoCD) {
        Install-ArgoCD
    }
    else {
        Write-Host "[i] Installation d'ArgoCD ignoree" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Deployer les applications
    Deploy-Applications -Env $Environment
    
    # Afficher le statut
    Show-Status
    
    # Afficher les informations d'acces
    Show-AccessInfo
    
    Write-Host "[OK] Deploiement termine avec succes!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[i] Conseil: Attendez quelques minutes que tous les pods soient en etat Running" -ForegroundColor Yellow
    Write-Host "   Verifiez avec: kubectl get pods -n online-boutique-dev" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "[X] Erreur lors du deploiement: $_" -ForegroundColor Red
    Write-Host ""
    exit 1
}
