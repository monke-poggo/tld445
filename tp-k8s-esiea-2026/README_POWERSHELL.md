# 🚀 Guide PowerShell - Online Boutique

Guide complet pour déployer et gérer l'application Online Boutique avec PowerShell sur Windows.

---

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir installé :

1. **Docker Desktop** - https://www.docker.com/products/docker-desktop
2. **Kind** - `choco install kind` ou https://kind.sigs.k8s.io/
3. **kubectl** - `choco install kubernetes-cli`
4. **PowerShell 5.1+** (inclus dans Windows)

### Vérification des prérequis

```powershell
# Vérifier Docker
docker version

# Vérifier Kind
kind version

# Vérifier kubectl
kubectl version --client
```

---

## 🚀 Déploiement Complet (Méthode Recommandée)

### Option 1 : Déploiement Automatique Complet

Un seul script pour tout installer :

```powershell
.\setup-complete.ps1
```

Ce script va :
1. ✅ Vérifier les prérequis
2. ✅ Créer le cluster Kind (3 nœuds)
3. ✅ Installer l'Ingress NGINX
4. ✅ Installer ArgoCD
5. ✅ Déployer les applications (dev + prod)
6. ✅ Afficher le statut et les URLs d'accès

**Temps estimé** : 5-10 minutes

---

### Option 2 : Déploiement Étape par Étape

Si vous préférez contrôler chaque étape :

#### 1. Créer le cluster Kind

```powershell
kind create cluster --name esiea-lab --config kind-config.yaml
```

#### 2. Vérifier le cluster

```powershell
kubectl cluster-info --context kind-esiea-lab
kubectl get nodes
```

#### 3. Installer l'Ingress NGINX

```powershell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Attendre que l'Ingress soit prêt
kubectl wait --namespace ingress-nginx `
  --for=condition=ready pod `
  --selector=app.kubernetes.io/component=controller `
  --timeout=90s
```

#### 4. Installer ArgoCD

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attendre qu'ArgoCD soit prêt
kubectl wait --namespace argocd `
  --for=condition=ready pod `
  --selector=app.kubernetes.io/name=argocd-server `
  --timeout=300s
```

#### 5. Récupérer le mot de passe ArgoCD

```powershell
$argoPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($argoPassword))
```

#### 6. Déployer les applications

```powershell
# Déployer dev et prod
.\deploy.ps1 all

# Ou séparément
.\deploy.ps1 dev
.\deploy.ps1 prod
```

---

## 🌐 Accéder à l'Application

### Méthode 1 : Script Automatique (Recommandé)

```powershell
# Ouvrir le frontend Dev
.\open-frontend.ps1 dev

# Ouvrir le frontend Prod
.\open-frontend.ps1 prod
```

Le script ouvre automatiquement votre navigateur à la bonne URL.

---

### Méthode 2 : Accès Direct via Ingress

Ouvrez simplement votre navigateur :

- **Dev** : http://localhost
- **Prod** : http://localhost/prod

---

### Méthode 3 : Port-Forward

```powershell
# Dev
kubectl port-forward -n online-boutique-dev svc/frontend-online-boutique-service 8080:8080

# Prod
kubectl port-forward -n online-boutique-prod svc/frontend-online-boutique-service 8081:8080
```

Puis ouvrir :
- Dev : http://localhost:8080
- Prod : http://localhost:8081

---

## 🔍 Vérification du Déploiement

### Vérifier les applications ArgoCD

```powershell
kubectl get applications -n argocd
```

Vous devriez voir 22 applications (11 dev + 11 prod).

---

### Vérifier les pods

```powershell
# Dev
kubectl get pods -n online-boutique-dev

# Prod
kubectl get pods -n online-boutique-prod
```

Tous les pods doivent être en état `Running`.

---

### Vérifier les services

```powershell
# Dev
kubectl get svc -n online-boutique-dev

# Prod
kubectl get svc -n online-boutique-prod
```

---

### Vérifier l'Ingress

```powershell
# Dev
kubectl get ingress -n online-boutique-dev

# Prod
kubectl get ingress -n online-boutique-prod
```

---

### Vérifier HPA (Production uniquement)

```powershell
kubectl get hpa -n online-boutique-prod
```

Vous devriez voir 9 HPA configurés.

---

### Vérifier PDB (Production uniquement)

```powershell
kubectl get pdb -n online-boutique-prod
```

---

### Vérifier les ConfigMaps

```powershell
# Dev
kubectl get configmap -n online-boutique-dev

# Prod
kubectl get configmap -n online-boutique-prod
```

---

### Vérifier les Secrets

```powershell
# Dev
kubectl get secret -n online-boutique-dev | Select-String "redis"

# Prod
kubectl get secret -n online-boutique-prod | Select-String "redis"
```

---

## 🔄 Accéder à ArgoCD

### Port-forward vers ArgoCD

```powershell
kubectl port-forward svc/argocd-server -n argocd 8082:443
```

### Ouvrir ArgoCD

URL : https://localhost:8082

**Credentials :**
- Username : `admin`
- Password : Récupérer avec :

```powershell
$argoPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($argoPassword))
```

---

## 🧹 Nettoyage

### Supprimer les applications (garder le cluster)

```powershell
.\cleanup.ps1
```

---

### Supprimer tout (y compris le cluster)

```powershell
.\cleanup.ps1 -DeleteCluster
```

---

### Suppression manuelle

```powershell
# Supprimer les applications ArgoCD
kubectl delete -k argocd/dev
kubectl delete -k argocd/prod

# Supprimer les namespaces
kubectl delete namespace online-boutique-dev
kubectl delete namespace online-boutique-prod

# Supprimer le cluster Kind
kind delete cluster --name esiea-lab
```

---

## 🔧 Commandes Utiles

### Voir tous les pods

```powershell
kubectl get pods --all-namespaces
```

---

### Voir les logs d'un pod

```powershell
kubectl logs -n online-boutique-dev <pod-name>

# Suivre les logs en temps réel
kubectl logs -n online-boutique-dev <pod-name> -f
```

---

### Redémarrer un déploiement

```powershell
kubectl rollout restart deployment/frontend-online-boutique-service -n online-boutique-dev
```

---

### Voir les événements

```powershell
kubectl get events -n online-boutique-dev --sort-by='.lastTimestamp'
```

---

### Voir l'utilisation des ressources

```powershell
kubectl top nodes
kubectl top pods -n online-boutique-prod
```

---

### Exécuter une commande dans un pod

```powershell
kubectl exec -it -n online-boutique-dev <pod-name> -- sh
```

---

## 🐛 Troubleshooting

### Problème : Pods en CrashLoopBackOff

```powershell
# Voir les logs
kubectl logs -n online-boutique-dev <pod-name>

# Décrire le pod
kubectl describe pod -n online-boutique-dev <pod-name>
```

---

### Problème : ArgoCD ne synchronise pas

```powershell
# Voir les détails de l'application
kubectl describe application -n argocd dev-frontend

# Forcer la synchronisation
kubectl patch application dev-frontend -n argocd --type merge --patch='{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

---

### Problème : Ingress ne fonctionne pas

```powershell
# Vérifier l'Ingress Controller
kubectl get pods -n ingress-nginx

# Redémarrer l'Ingress Controller
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx

# Vérifier les logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

---

### Problème : HPA ne scale pas

```powershell
# Vérifier les métriques
kubectl top pods -n online-boutique-prod

# Vérifier le metrics-server
kubectl get deployment metrics-server -n kube-system
```

Si metrics-server n'est pas installé :

```powershell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

## 📊 Scripts Disponibles

| Script | Description | Usage |
|--------|-------------|-------|
| `setup-complete.ps1` | Déploiement complet automatique | `.\setup-complete.ps1` |
| `deploy.ps1` | Déployer les applications | `.\deploy.ps1 all` |
| `open-frontend.ps1` | Ouvrir le frontend | `.\open-frontend.ps1 dev` |
| `cleanup.ps1` | Nettoyer le déploiement | `.\cleanup.ps1` |

---

## 🎯 Workflow Recommandé

### Premier déploiement

```powershell
# 1. Déploiement complet
.\setup-complete.ps1

# 2. Attendre que tout soit prêt (2-3 minutes)
kubectl get pods -n online-boutique-dev --watch

# 3. Ouvrir le frontend
.\open-frontend.ps1 dev
```

---

### Redéploiement après modifications

```powershell
# Si le cluster existe déjà
.\setup-complete.ps1 -SkipClusterCreation -SkipIngress -SkipArgoCD

# Ou juste redéployer les applications
.\deploy.ps1 all
```

---

### Nettoyage et redémarrage

```powershell
# Nettoyer sans supprimer le cluster
.\cleanup.ps1

# Redéployer
.\setup-complete.ps1 -SkipClusterCreation
```

---

## 💡 Astuces PowerShell

### Créer un alias pour kubectl

```powershell
Set-Alias -Name k -Value kubectl
```

Puis utiliser :

```powershell
k get pods -n online-boutique-dev
```

---

### Surveiller les pods en temps réel

```powershell
kubectl get pods -n online-boutique-dev --watch
```

---

### Obtenir les logs de tous les pods d'un déploiement

```powershell
kubectl logs -n online-boutique-dev deployment/frontend-online-boutique-service --all-containers=true
```

---

## 📚 Documentation Complète

- `README.md` - Documentation générale
- `QUICKSTART.md` - Guide de démarrage rapide
- `ACCES_FRONTEND.md` - Guide d'accès au frontend
- `AMELIORATIONS.md` - Liste des améliorations
- `VALIDATION.md` - Validation du projet

---

## 🎓 Pour le Rendu GitLab

Une fois que tout fonctionne localement :

```powershell
# 1. Créer une branche
git checkout -b poggi_victor

# 2. Ajouter les fichiers
git add .

# 3. Commit
git commit -m "TP ESIEA 2026 - K8s - POGGI Victor - Projet complet"

# 4. Push
git push origin poggi_victor
```

Puis créer une Merge Request sur GitLab.

---

**Bon déploiement ! 🚀**
