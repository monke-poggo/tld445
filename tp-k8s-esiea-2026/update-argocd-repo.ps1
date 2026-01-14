# Script pour mettre à jour le repoURL dans tous les manifests ArgoCD
# Usage: .\update-argocd-repo.ps1

Write-Host "[*] Mise a jour des manifests ArgoCD vers GitHub..." -ForegroundColor Yellow

$services = @(
    "adservice",
    "cartservice", 
    "checkoutservice",
    "currencyservice",
    "emailservice",
    "frontend",
    "paymentservice",
    "productcatalogservice",
    "recommendationservice",
    "redis",
    "shippingservice"
)

$environments = @("dev", "prod")

$oldRepo = "https://gitlab.esiea.fr/bastien.ceriani/k8s-gitops.git"
$newRepo = "https://github.com/monke-poggo/tld445.git"

$count = 0
foreach ($env in $environments) {
    foreach ($service in $services) {
        $file = "argocd/$env/$service.yaml"
        
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            
            # Remplacer l'URL et commenter l'ancienne
            $newContent = $content -replace "repoURL: $([regex]::Escape($oldRepo))", "# repoURL: $oldRepo (GitLab ESIEA - pour le rendu final)`n    repoURL: $newRepo"
            
            Set-Content -Path $file -Value $newContent -NoNewline
            $count++
            Write-Host "[OK] $file" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "[OK] $count manifests mis a jour" -ForegroundColor Green
Write-Host "[i] Ancien repo (commente): $oldRepo" -ForegroundColor Cyan
Write-Host "[i] Nouveau repo (actif): $newRepo" -ForegroundColor Cyan
