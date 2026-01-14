# Script pour corriger le path dans tous les manifests ArgoCD
Write-Host "[*] Correction du path dans les manifests ArgoCD..." -ForegroundColor Yellow

$services = @(
    "adservice", "cartservice", "checkoutservice", "currencyservice",
    "emailservice", "frontend", "paymentservice", "productcatalogservice",
    "recommendationservice", "redis", "shippingservice"
)

$environments = @("dev", "prod")
$count = 0

foreach ($env in $environments) {
    foreach ($service in $services) {
        $file = "argocd/$env/$service.yaml"
        
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            
            # Remplacer le path
            $newContent = $content -replace "path: tp-k8s-esiea-2026/poggi_victor/charts", "path: tp-k8s-esiea-2026/charts"
            
            Set-Content -Path $file -Value $newContent -NoNewline
            $count++
            Write-Host "[OK] $file" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "[OK] $count manifests corriges" -ForegroundColor Green
Write-Host "[i] Nouveau path: tp-k8s-esiea-2026/charts" -ForegroundColor Cyan
