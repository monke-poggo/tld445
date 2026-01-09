# TP Kubernetes ESIEA 2026 - Online Boutique GitOps

Ce projet implémente un déploiement GitOps complet de l'application **Online Boutique** de Google en utilisant Kubernetes, Helm et ArgoCD.

## Architecture

L'application Online Boutique est composée de 11 microservices :

### Services applicatifs
- **frontend** - Interface utilisateur web (port 8080)
- **productcatalogservice** - Catalogue produits (port 3550)
- **cartservice** - Gestion du panier (port 7070)
- **paymentservice** - Traitement des paiements (port 50051)
- **recommendationservice** - Recommandations (port 8080)
- **checkoutservice** - Orchestration des commandes (port 5050)
- **currencyservice** - Conversion monétaire (port 7000)
- **adservice** - Génération d'annonces (port 9555)
- **shippingservice** - Calcul des frais de livraison (port 50051)
- **emailservice** - Service d'email (port 5000)

### Services d'infrastructure
- **redis** - Base de données clé/valeur (port 6379)

## Structure du projet

```
tp-k8s-esiea-2026/
├── charts/                           # Helm Chart générique
│   ├── Chart.yaml                   # Métadonnées du chart
│   ├── values.yaml                  # Values par défaut
│   └── templates/                   # Templates Kubernetes
│       ├── deployment.yaml          # Deployment standard
│       ├── statefulset.yaml         # StatefulSet (pour Redis)
│       ├── service.yaml             # Service
│       ├── ingress.yaml             # Ingress
│       ├── networkpolicy.yaml       # NetworkPolicy
│       └── _helpers.tpl             # Fonctions Helm
├── helm-values/                     # Configurations par environnement
│   ├── dev/                         # Environnement développement
│   │   ├── frontend.yaml
│   │   ├── productcatalogservice.yaml
│   │   ├── cartservice.yaml
│   │   ├── paymentservice.yaml
│   │   ├── recommendationservice.yaml
│   │   ├── checkoutservice.yaml
│   │   ├── currencyservice.yaml
│   │   ├── adservice.yaml
│   │   ├── shippingservice.yaml
│   │   ├── emailservice.yaml
│   │   └── redis.yaml
│   └── prod/                        # Environnement production
│       ├── frontend.yaml
│       ├── productcatalogservice.yaml
│       ├── cartservice.yaml
│       ├── paymentservice.yaml
│       ├── recommendationservice.yaml
│       ├── checkoutservice.yaml
│       ├── currencyservice.yaml
│       ├── adservice.yaml
│       ├── shippingservice.yaml
│       ├── emailservice.yaml
│       └── redis.yaml
├── argocd/                          # Manifests ArgoCD
│   ├── base/                        # Templates de base
│   │   └── application.yaml
│   ├── dev/                         # Applications dev
│   │   ├── kustomization.yaml
│   │   ├── frontend.yaml
│   │   ├── productcatalogservice.yaml
│   │   ├── cartservice.yaml
│   │   ├── paymentservice.yaml
│   │   ├── recommendationservice.yaml
│   │   ├── checkoutservice.yaml
│   │   ├── currencyservice.yaml
│   │   ├── adservice.yaml
│   │   ├── shippingservice.yaml
│   │   ├── emailservice.yaml
│   │   └── redis.yaml
│   └── prod/                        # Applications prod
│       ├── kustomization.yaml
│       ├── frontend.yaml
│       ├── productcatalogservice.yaml
│       ├── cartservice.yaml
│       ├── paymentservice.yaml
│       ├── recommendationservice.yaml
│       ├── checkoutservice.yaml
│       ├── currencyservice.yaml
│       ├── adservice.yaml
│       ├── shippingservice.yaml
│       ├── emailservice.yaml
│       └── redis.yaml
├── kind-config.yaml                 # Configuration cluster Kind
└── README.md                        # Documentation
```

## Prérequis

- Docker
- Kind
- kubectl
- Helm (optionnel pour les tests)

## Installation

### 1. Création du cluster Kind

```bash
kind create cluster --name esiea-lab --config kind-config.yaml
kubectl cluster-info --context kind-esiea-lab
```

### 2. Installation de l'ingress NGINX

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### 3. Installation d'ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=300s
```

## Déploiement

### Déploiement automatique avec script

```bash
# Linux/Mac
./deploy.sh all

# Windows PowerShell
.\deploy.ps1 all
```

### Déploiement manuel des environnements via ArgoCD

```bash
# Déploiement environnement dev
kubectl apply -k argocd/dev

# Déploiement environnement prod
kubectl apply -k argocd/prod
```

### Vérification du déploiement

```bash
# Vérifier les applications ArgoCD
kubectl get applications -n argocd

# Vérifier les pods dev
kubectl get pods -n online-boutique-dev

# Vérifier les pods prod
kubectl get pods -n online-boutique-prod

# Vérifier les services
kubectl get svc -n online-boutique-dev
kubectl get svc -n online-boutique-prod
```

## Accès à l'application

### Environnement dev
```bash
# Port-forward vers le frontend dev
kubectl port-forward -n online-boutique-dev svc/frontend-online-boutique-service 8080:8080
```
Accès : http://localhost:8080

### Environnement prod
```bash
# Port-forward vers le frontend prod
kubectl port-forward -n online-boutique-prod svc/frontend-online-boutique-service 8081:8080
```
Accès : http://localhost:8081

### Via Ingress (si configuré)
- Dev : http://online-boutique-dev.local
- Prod : http://online-boutique-prod.local

## Accès à ArgoCD

```bash
# Port-forward vers ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8082:443
```
Accès : https://localhost:8082
- Username : admin
- Password : 3H-sejo-MRftTQTu

## Caractéristiques techniques

### Différences Dev/Prod

| Aspect | Dev | Prod |
|--------|-----|------|
| Replicas | 1 | 2 |
| Ressources CPU | 100-300m | 150-500m |
| Ressources RAM | 64-256Mi | 128-512Mi |
| Ingress | Activé (dev.local) | Activé (prod.local) |
| Persistance Redis | 1Gi | 5Gi |

### Health Checks

- **HTTP Services** : frontend (/_healthz)
- **gRPC Services** : tous les autres services
- **Redis** : TCP + redis-cli ping

### Sécurité

- NetworkPolicy activée pour Redis (accès restreint au cartservice)
- RBAC configuré avec principe du moindre privilège pour chaque service
- ServiceAccount dédié par service
- Secrets séparés par environnement
- Pas d'exposition externe sauf frontend via Ingress
- Permissions minimales : services n'accèdent qu'aux ressources nécessaires

### Persistance

- Redis utilise un StatefulSet avec PersistentVolumeClaim
- Données persistées dans /data
- Taille configurable par environnement

## Tests

### Test manuel des services

```bash
# Test du frontend
curl http://localhost:8080

# Test des services internes (via port-forward)
kubectl port-forward -n online-boutique-dev svc/productcatalogservice-online-boutique-service 3550:3550
```

### Test avec Helm (optionnel)

```bash
# Test du template
helm template frontend ./charts -f helm-values/dev/frontend.yaml

# Déploiement direct avec Helm
helm install frontend ./charts -f helm-values/dev/frontend.yaml -n online-boutique-dev --create-namespace
```

## Troubleshooting

### Problèmes courants

1. **Pods en CrashLoopBackOff**
   ```bash
   kubectl logs -n online-boutique-dev <pod-name>
   kubectl describe pod -n online-boutique-dev <pod-name>
   ```

2. **Services non accessibles**
   ```bash
   kubectl get svc -n online-boutique-dev
   kubectl get endpoints -n online-boutique-dev
   ```

3. **ArgoCD sync issues**
   ```bash
   kubectl get applications -n argocd
   kubectl describe application -n argocd <app-name>
   ```

### Commandes utiles

```bash
# Redémarrer un déploiement
kubectl rollout restart deployment/<service>-online-boutique-service -n online-boutique-dev

# Forcer la synchronisation ArgoCD
kubectl patch application <app-name> -n argocd --type merge --patch='{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

# Nettoyer un environnement
kubectl delete namespace online-boutique-dev
kubectl delete namespace online-boutique-prod
```

## Bonnes pratiques implémentées

- ✅ Séparation des environnements (dev/prod)
- ✅ Cycle de vie indépendant par service
- ✅ Configuration externalisée via Helm values
- ✅ Health checks appropriés (HTTP/gRPC/TCP)
- ✅ Gestion des ressources (limits/requests)
- ✅ Persistance pour les données critiques (Redis StatefulSet)
- ✅ Sécurité réseau (NetworkPolicy pour Redis)
- ✅ RBAC avec principe du moindre privilège
- ✅ ServiceAccount dédié par service
- ✅ Déploiement GitOps avec ArgoCD
- ✅ Labels et annotations cohérents
- ✅ Nommage standardisé des services
- ✅ Scripts de déploiement automatisés
- ✅ Documentation complète

## Améliorations possibles

- HPA (Horizontal Pod Autoscaler) pour la scalabilité automatique
- PDB (Pod Disruption Budget) pour la résilience
- Monitoring avec Prometheus/Grafana
- Logging centralisé avec ELK/Loki
- Secrets management avec External Secrets Operator
- Service Mesh (Istio) pour la sécurité avancée
- Tests automatisés avec Helm unittest