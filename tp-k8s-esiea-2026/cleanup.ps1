# Script PowerShell pour nettoyer le déploiement Online Boutique
# Auteur: Victor Poggi
# Date: Janvier 2026

param(
    [switch]$DeleteCluster,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Red
Write-Host "  NETTOYAGE Online Boutique" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

# Confirmation
if (-not $Force) {
    Write-Host "[!] ATTENTION: Cette operation va supprimer:" -ForegroundColor Yellow
    Write-Host "   - Toutes les applications ArgoCD" -ForegroundColor Yellow
    Write-Host "   - Les namespaces online-boutique-dev et online-boutique-prod" -ForegroundColor Yellow
    
    if ($DeleteCluster) {
        Write-Host "   - Le cluster Kind 'esiea-lab'" -ForegroundColor Red
    }
    
    Write-Host ""
    $response = Read-Host "Etes-vous sur de vouloir continuer? (o/N)"
    
    if ($response -ne "o" -and $response -ne "O") {
        Write-Host "[X] Operation annulee" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""

# Fonction pour supprimer les applications ArgoCD
function Remove-ArgoApplications {
    Write-Host "[*] Suppression des applications ArgoCD..." -ForegroundColor Yellow
    
    try {
        # Supprimer les applications dev
        Write-Host "  [*] Suppression des applications DEV..." -ForegroundColor Cyan
        kubectl delete -k argocd/dev 2>$null
        
        # Supprimer les applications prod
        Write-Host "  [*] Suppression des applications PROD..." -ForegroundColor Cyan
        kubectl delete -k argocd/prod 2>$null
        
        Write-Host "  [OK] Applications ArgoCD supprimees" -ForegroundColor Green
    }
    catch {
        Write-Host "  [!] Erreur lors de la suppression des applications: $_" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Fonction pour supprimer les namespaces
function Remove-Namespaces {
    Write-Host "[*] Suppression des namespaces..." -ForegroundColor Yellow
    
    try {
        # Supprimer le namespace dev
        $devNamespace = kubectl get namespace online-boutique-dev 2>$null
        if ($devNamespace) {
            Write-Host "  [*] Suppression du namespace online-boutique-dev..." -ForegroundColor Cyan
            kubectl delete namespace online-boutique-dev
            Write-Host "  [OK] Namespace dev supprime" -ForegroundColor Green
        }
        else {
            Write-Host "  [i] Namespace dev n'existe pas" -ForegroundColor Cyan
        }
        
        # Supprimer le namespace prod
        $prodNamespace = kubectl get namespace online-boutique-prod 2>$null
        if ($prodNamespace) {
            Write-Host "  [*] Suppression du namespace online-boutique-prod..." -ForegroundColor Cyan
            kubectl delete namespace online-boutique-prod
            Write-Host "  [OK] Namespace prod supprime" -ForegroundColor Green
        }
        else {
            Write-Host "  [i] Namespace prod n'existe pas" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "  [!] Erreur lors de la suppression des namespaces: $_" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Fonction pour supprimer le cluster Kind
function Remove-KindCluster {
    Write-Host "[*] Suppression du cluster Kind..." -ForegroundColor Yellow
    
    try {
        $existingCluster = kind get clusters 2>$null | Where-Object { $_ -eq "esiea-lab" }
        
        if ($existingCluster) {
            Write-Host "  [*] Suppression du cluster 'esiea-lab'..." -ForegroundColor Cyan
            kind delete cluster --name esiea-lab
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Cluster supprime" -ForegroundColor Green
            }
            else {
                Write-Host "  [X] Erreur lors de la suppression du cluster" -ForegroundColor Red
            }
        }
        else {
            Write-Host "  [i] Le cluster 'esiea-lab' n'existe pas" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "  [!] Erreur lors de la suppression du cluster: $_" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Script principal
try {
    # Verifier que kubectl est disponible
    try {
        kubectl version --client | Out-Null
    }
    catch {
        Write-Host "[X] kubectl n'est pas installe" -ForegroundColor Red
        exit 1
    }
    
    # Supprimer les applications ArgoCD
    Remove-ArgoApplications
    
    # Supprimer les namespaces
    Remove-Namespaces
    
    # Supprimer le cluster si demande
    if ($DeleteCluster) {
        Remove-KindCluster
    }
    else {
        Write-Host "[i] Le cluster Kind n'a pas ete supprime" -ForegroundColor Cyan
        Write-Host "   Pour le supprimer, utilisez: .\cleanup.ps1 -DeleteCluster" -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  [OK] Nettoyage termine!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    if (-not $DeleteCluster) {
        Write-Host "[i] Le cluster Kind est toujours actif" -ForegroundColor Yellow
        Write-Host "   Vous pouvez redeployer avec: .\setup-complete.ps1 -SkipClusterCreation" -ForegroundColor Cyan
        Write-Host ""
    }
}
catch {
    Write-Host ""
    Write-Host "[X] Erreur lors du nettoyage: $_" -ForegroundColor Red
    Write-Host ""
    exit 1
}
