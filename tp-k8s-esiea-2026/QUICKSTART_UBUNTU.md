# Quick Start - Ubuntu Server

Guide de déploiement rapide sur Ubuntu Server vierge avec Kind.

## Installation

```bash
# Mise à jour système
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git openssh

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Helm (optionnel)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Déploiement

```bash
# Cloner le repo
git clone <URL_REPO> tp-k8s-esiea-2026
cd tp-k8s-esiea-2026

# Créer le cluster
kind create cluster --name esiea-lab --config kind-config.yaml

# Installer NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

# Installer ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=300s

# Récupérer le mot de passe ArgoCD
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Déployer les applications
kubectl apply -k argocd/dev
kubectl apply -k argocd/prod
```

## Configuration /etc/hosts

```bash
# Ajouter les entrées au fichier hosts
sudo bash -c 'cat >> /etc/hosts << EOF
127.0.0.1 online-boutique-dev.local
127.0.0.1 online-boutique-prod.local
EOF'
```

## Accès

Via Ingress (recommandé):
- Dev: http://online-boutique-dev.local
- Prod: http://online-boutique-prod.local

Via Port-Forward:
```bash
# Frontend Dev (port 8080)
kubectl port-forward -n online-boutique-dev svc/frontend-online-boutique-service 8080:8080

# Frontend Prod (port 8081)
kubectl port-forward -n online-boutique-prod svc/frontend-online-boutique-service 8081:8080

# ArgoCD UI (port 8082)
kubectl port-forward svc/argocd-server -n argocd 8082:443
# Username: admin
# Password: voir commande ci-dessus
```

## Vérification

```bash
kubectl get nodes
kubectl get applications -n argocd
kubectl get pods -n online-boutique-dev
kubectl get pods -n online-boutique-prod
```

## Nettoyage

```bash
kind delete cluster --name esiea-lab
```
