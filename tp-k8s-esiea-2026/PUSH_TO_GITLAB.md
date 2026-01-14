# Push to GitLab - Instructions

## Current Status
- ✅ Cluster created and running
- ✅ ArgoCD installed and ready
- ✅ 22 ArgoCD Applications created (11 dev + 11 prod)
- ✅ Probe configuration fixed (empty defaults in values.yaml)
- ❌ Code not yet in GitLab - ArgoCD cannot sync

## Error Message
```
Failed to load target state: authentication required: HTTP Basic: Access denied
```

## Solution: Push Your Code to GitLab

### Step 1: Initialize Git (if not already done)
```powershell
cd tp-k8s-esiea-2026
git init
git add .
git commit -m "Initial commit: Online Boutique K8s GitOps project"
```

### Step 2: Add GitLab Remote
```powershell
git remote add origin https://gitlab.esiea.fr/bastien.ceriani/k8s-gitops.git
```

### Step 3: Create Your Branch
```powershell
# Create a branch with your name
git checkout -b poggi_victor
```

### Step 4: Push to GitLab
```powershell
# Push your branch
git push -u origin poggi_victor

# Or if you need to push to main:
git push -u origin main
```

**Note**: You may need to authenticate with your GitLab credentials or personal access token.

### Step 5: Verify ArgoCD Sync
After pushing, wait 1-2 minutes and check:

```powershell
# Check ArgoCD applications status
kubectl get applications -n argocd

# Check pods in dev namespace
kubectl get pods -n online-boutique-dev

# Check pods in prod namespace
kubectl get pods -n online-boutique-prod
```

## Expected Result After Push

All applications should show:
- SYNC STATUS: Synced
- HEALTH STATUS: Healthy

All pods should be Running:
```
NAME                                     READY   STATUS    RESTARTS   AGE
adservice-xxx                            1/1     Running   0          2m
cartservice-xxx                          1/1     Running   0          2m
checkoutservice-xxx                      1/1     Running   0          2m
currencyservice-xxx                      1/1     Running   0          2m
emailservice-xxx                         1/1     Running   0          2m
frontend-xxx                             1/1     Running   0          2m
paymentservice-xxx                       1/1     Running   0          2m
productcatalogservice-xxx                1/1     Running   0          2m
recommendationservice-xxx                1/1     Running   0          2m
redis-0                                  1/1     Running   0          2m
shippingservice-xxx                      1/1     Running   0          2m
```

## Access Frontend After Deployment

### DEV Environment
```powershell
.\open-frontend.ps1 dev
# Or directly: http://localhost
```

### PROD Environment
```powershell
.\open-frontend.ps1 prod
# Or directly: http://localhost/prod
```

## Troubleshooting

### If ArgoCD still shows "Unknown" after push:
```powershell
# Force sync all applications
kubectl patch application dev-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

# Or use ArgoCD CLI
argocd app sync dev-frontend
```

### If you get authentication errors:
1. Make sure you have access to the GitLab repository
2. Create a personal access token in GitLab (Settings > Access Tokens)
3. Use the token as password when pushing

### Check ArgoCD logs:
```powershell
kubectl logs -n argocd deployment/argocd-repo-server
```

## Important Files Changed
- `tp-k8s-esiea-2026/charts/values.yaml` - Fixed probe defaults (now empty)
- All ArgoCD manifests point to: `https://gitlab.esiea.fr/bastien.ceriani/k8s-gitops.git`
- Path: `tp-k8s-esiea-2026/poggi_victor/charts`
- Branch: `main`

## What Was Fixed
The probe configuration issue has been resolved:
- **Before**: `values.yaml` had default httpGet probes that merged with service-specific probes
- **After**: `values.yaml` has empty probes (`livenessProbe: {}`, `readinessProbe: {}`)
- **Result**: Each service can now define its own probe type (httpGet, grpc, tcpSocket) without conflicts

This fix allows:
- Frontend: httpGet probes ✅
- Cart/Checkout/etc: grpc probes ✅
- Redis: tcpSocket probes ✅
