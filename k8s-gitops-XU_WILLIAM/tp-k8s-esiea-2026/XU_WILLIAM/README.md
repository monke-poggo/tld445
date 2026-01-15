# TP Kubernetes GitOps - Online Boutique avec ArgoCD

Déploiement complet de l'application **Online Boutique** (microservices e-commerce de Google) sur Kubernetes en utilisant **ArgoCD** pour le GitOps et **Helm** pour le packaging.

## 📐 Architecture du Projet

```
kubernetes2/
├── argocd/              # Configuration ArgoCD (GitOps)
│   ├── base/          # ArgoCD installation + SSH config
│   ├── dev/           # Applications ArgoCD pour DEV (12 services)
│   └── prod/          # Applications ArgoCD pour PROD (12 services)
├── charts/            # Helm Chart générique (réutilisable)
│   └── online-boutique-service/
│       ├── templates/ # Templates Kubernetes (Deployment, Service, HPA, etc.)
│       └── values.yaml # Valeurs par défaut
├── helm-values/       # Values spécifiques par service et environnement
│   ├── dev/          # 12 fichiers (1 par service) pour DEV
│   └── prod/         # 12 fichiers (1 par service) pour PROD
├── start-cluster.sh   # Script de création du cluster Kind
└── shutdown-cluster.sh # Script de suppression du cluster
```

**Principe**: Un seul Helm Chart générique + des fichiers values différents = Déploiement de 12 microservices × 2 environnements = 24 déploiements avec ArgoCD.

---

## 🚀 Guide de Déploiement

### Étape 1 : Créer le cluster Kubernetes
```bash
./start-cluster.sh
```
Crée un cluster Kind local avec le nom `esiea-gitops-cluster`.

### Étape 2 : Déployer l'environnement DEV
```bash
kubectl apply -k argocd/dev/    # 1ère fois (erreur CRDs = NORMALE)
kubectl apply -k argocd/dev/    # 2ème fois (OK, tout se déploie)
```

**⚠️ Pourquoi lancer 2 fois ?**
La première commande crée les **CRDs** (Custom Resource Definitions) d'ArgoCD, mais Kubernetes n'a pas encore eu le temps de les enregistrer. La deuxième commande applique les **Applications** ArgoCD qui utilisent ces CRDs.

### Étape 3 : Déployer l'environnement PROD (optionnel)
```bash
kubectl apply -k argocd/prod/   # 1ère fois
kubectl apply -k argocd/prod/   # 2ème fois
```

### Étape 4 : Attendre le déploiement
```bash
# Vérifier que ArgoCD est prêt (2-3 minutes)
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Vérifier l'état des applications
kubectl get applications -n argocd
```

Tous les services doivent être **Synced** et **Healthy**.

---

## 🌐 Accès aux Services

### ArgoCD UI (Interface de gestion GitOps)
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```
- **URL**: https://localhost:8080
- **Username**: `admin`
- **Password**: 
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo
  ```

### Online Boutique DEV (Application e-commerce)
```bash
kubectl port-forward -n online-boutique-dev svc/frontend 8081:80
```
- **URL**: http://localhost:8081

### Online Boutique PROD
```bash
kubectl port-forward -n online-boutique-prod svc/frontend 8082:80
```
- **URL**: http://localhost:8082

### Alternative : Accès via Ingress
Ajouter dans `/etc/hosts` :
```bash
echo '127.0.0.1 dev.online-boutique.local' | sudo tee -a /etc/hosts
echo '127.0.0.1 prod.online-boutique.local' | sudo tee -a /etc/hosts
```
Puis ouvrir:
- DEV: http://dev.online-boutique.local
- PROD: http://prod.online-boutique.local

---

## 🛑 Arrêter le Cluster

```bash
./shutdown-cluster.sh
```
Supprime toutes les applications ArgoCD, les namespaces et le cluster Kind.

---

## 🎯 Services Déployés

L'application comprend **12 microservices** :

| Service | Langage | Port | Protocole | Description |
|---------|---------|------|-----------|-------------|
| frontend | Go | 8080 | HTTP | Interface utilisateur web |
| cartservice | C# | 7070 | gRPC | Gestion du panier |
| productcatalogservice | Go | 3550 | gRPC | Catalogue produits |
| currencyservice | Node.js | 7000 | gRPC | Conversion de devises |
| paymentservice | Node.js | 50051 | gRPC | Traitement paiements |
| shippingservice | Go | 50051 | gRPC | Calcul frais de port |
| emailservice | Python | 8080 | gRPC | Envoi d'emails |
| checkoutservice | Go | 5050 | gRPC | Orchestration checkout |
| recommendationservice | Python | 8080 | gRPC | Recommandations |
| adservice | Java | 9555 | gRPC | Publicités |
| redis-cart | Redis | 6379 | Redis | Base de données panier |
| loadgenerator | Python | - | - | Génération de charge |

---

## 🔧 Différences DEV vs PROD

| Critère | DEV | PROD |
|---------|-----|------|
| **Replicas** | 1 pod | 2-3 pods |
| **CPU/RAM** | Limité (200m/128Mi) | Élevé (300m/256Mi) |
| **HPA** | Activé (test) | Activé (production) |
| **PDB** | Activé | Activé |
| **Ingress** | Activé (frontend) | Activé (frontend) |

---

## 🐛 Troubleshooting

### Erreur: `no matches for kind "Application"`
**Cause**: Les CRDs ArgoCD ne sont pas encore enregistrés.  
**Solution**: Relancer `kubectl apply -k argocd/dev/` une 2ème fois.

### Pods en `ImagePullBackOff`
**Cause**: Image Docker introuvable ou mauvais tag.  
**Solution**: Vérifier le fichier `helm-values/.../service.yaml` (tag `v0.10.1`).

### Service ne répond pas
**Cause**: Probes en échec (health checks).  
**Solution**: Vérifier les logs avec `kubectl logs -n online-boutique-dev <pod-name>`.

### ArgoCD affiche "Unknown" ou "OutOfSync"
**Cause**: Changement dans Git non détecté.  
**Solution**: Forcer la synchro manuellement dans l'UI ArgoCD ou avec :
```bash
kubectl patch application <app-name> -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"normal"}}}'
```

---

## 📚 Ressources Utiles

- [Documentation ArgoCD](https://argo-cd.readthedocs.io/)
- [Helm Charts](https://helm.sh/docs/topics/charts/)
- [Online Boutique (Google)](https://github.com/GoogleCloudPlatform/microservices-demo)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

---

## 🎓 Concepts Clés Utilisés

- **GitOps**: Git comme source de vérité (ArgoCD)
- **Helm Chart générique**: Réutilisabilité
- **Kustomize**: Gestion multi-environnements
- **HPA**: Auto-scaling horizontal
- **PDB**: Haute disponibilité
- **Probes**: Health checks (liveness/readiness)
- **RBAC**: Permissions Kubernetes
- **Ingress**: Exposition HTTP/HTTPS
- **NetworkPolicy**: Sécurité réseau (désactivé par défaut)
- **SecurityContext**: Sécurité des containers (désactivé par défaut)
