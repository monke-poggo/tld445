#!/bin/bash

# Script de démarrage du cluster Kubernetes pour le TP GitOps ArgoCD
# Usage: ./start-cluster.sh

set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== TP GitOps ArgoCD - Démarrage du cluster ===${NC}\n"

# Vérification des prérequis
echo -e "${YELLOW}[1/4] Vérification des prérequis...${NC}"

if ! command -v kind &> /dev/null; then
    echo -e "${RED}❌ kind n'est pas installé. Installez-le depuis: https://kind.sigs.k8s.io/docs/user/quick-start/#installation${NC}"
    exit 1
fi
echo "  ✓ kind est installé ($(kind version))"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl n'est pas installé. Installez-le depuis: https://kubernetes.io/docs/tasks/tools/${NC}"
    exit 1
fi
echo "  ✓ kubectl est installé ($(kubectl version --client -o yaml | grep gitVersion | head -1))"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ docker n'est pas installé ou n'est pas en cours d'exécution${NC}"
    exit 1
fi
echo "  ✓ docker est disponible"

# Nom du cluster
CLUSTER_NAME="esiea-gitops-cluster"

# Vérification si le cluster existe déjà
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "\n${YELLOW}⚠️  Le cluster '${CLUSTER_NAME}' existe déjà.${NC}"
    read -p "Voulez-vous le supprimer et le recréer ? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Suppression du cluster existant...${NC}"
        kind delete cluster --name "${CLUSTER_NAME}"
    else
        echo -e "${GREEN}✓ Utilisation du cluster existant${NC}"
        kubectl cluster-info --context "kind-${CLUSTER_NAME}"
        exit 0
    fi
fi

# Création du cluster
echo -e "\n${YELLOW}[2/4] Création du cluster kind '${CLUSTER_NAME}'...${NC}"

cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      # Port pour Nginx Ingress HTTP
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      # Port pour Nginx Ingress HTTPS
      - containerPort: 443
        hostPort: 443
        protocol: TCP
      # Ports NodePort pour accès direct
      - containerPort: 30080
        hostPort: 30080
        protocol: TCP
      - containerPort: 30443
        hostPort: 30443
        protocol: TCP
EOF

# Attendre que le cluster soit prêt
echo -e "\n${YELLOW}[3/6] Attente de la disponibilité du cluster...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Installation de Nginx Ingress Controller
echo -e "\n${YELLOW}[4/6] Installation de Nginx Ingress Controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo -e "${YELLOW}Attente du démarrage de l'Ingress Controller...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo "  ✓ Nginx Ingress Controller est prêt"

# Vérification finale
echo -e "\n${YELLOW}[5/6] Vérification du cluster...${NC}"
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

echo -e "\n${YELLOW}[6/6] Vérification des composants...${NC}"
kubectl get pods -n ingress-nginx

echo -e "\n${GREEN}✓✓✓ Cluster créé avec succès ! ✓✓✓${NC}\n"
echo -e "${GREEN}Prochaines étapes :${NC}"
echo -e "  1. Déployer ArgoCD et les applications en dev :"
echo -e "     ${YELLOW}kubectl apply -k argocd/dev/${NC}"
echo -e "     ${YELLOW}kubectl apply -k argocd/dev/${NC} (relancer 2x pour les CRDs)"
echo -e ""
echo -e "  2. Ou déployer en production :"
echo -e "     ${YELLOW}kubectl apply -k argocd/prod/${NC}"
echo -e ""
echo -e "  3. Attendre que ArgoCD soit prêt (peut prendre 2-3 minutes) :"
echo -e "     ${YELLOW}kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s${NC}"
echo -e ""
echo -e "  4. Obtenir le mot de passe admin ArgoCD :"
echo -e "     ${YELLOW}kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo${NC}"
echo -e ""
echo -e "  5. Accéder aux services :"
echo -e "     ${YELLOW}./access-services.sh${NC}"
echo -e "     ArgoCD: ${YELLOW}https://localhost:8080${NC} (user: admin)"
echo -e "     Online Boutique DEV: ${YELLOW}http://localhost:8081${NC}"
echo ""
