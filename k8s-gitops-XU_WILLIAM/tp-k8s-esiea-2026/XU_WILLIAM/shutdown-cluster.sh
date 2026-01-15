#!/bin/bash

# Script d'arrêt du cluster Kubernetes pour le TP GitOps ArgoCD
# Usage: ./shutdown-cluster.sh

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

CLUSTER_NAME="esiea-gitops-cluster"

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🛑 Arrêt et nettoyage du cluster Kubernetes${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier que le cluster existe
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${RED}❌ Le cluster '${CLUSTER_NAME}' n'existe pas${NC}"
    exit 0
fi

echo -e "${YELLOW}[1/4] Suppression des applications ArgoCD...${NC}"
kubectl delete applications --all -n argocd 2>/dev/null || echo "  ⚠ Pas d'applications à supprimer"

echo -e "${YELLOW}[2/4] Suppression des namespaces applicatifs...${NC}"
kubectl delete namespace online-boutique-dev 2>/dev/null || echo "  ⚠ Namespace online-boutique-dev n'existe pas"
kubectl delete namespace online-boutique-prod 2>/dev/null || echo "  ⚠ Namespace online-boutique-prod n'existe pas"

echo -e "${YELLOW}[3/4] Suppression du namespace ArgoCD...${NC}"
kubectl delete namespace argocd 2>/dev/null || echo "  ⚠ Namespace argocd n'existe pas"

echo -e "${YELLOW}[4/4] Suppression du cluster Kind '${CLUSTER_NAME}'...${NC}"
kind delete cluster --name "${CLUSTER_NAME}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Cluster et tous les services supprimés !${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}💡 Pour redémarrer le cluster, exécutez:${NC}"
echo -e "   ${YELLOW}./start-cluster.sh${NC}"
echo ""
