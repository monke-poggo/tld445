#!/bin/bash
set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Démarrage des port-forwards...${NC}"
echo ""

# Fonction pour vérifier si un port est déjà utilisé
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${YELLOW}⚠ Port $port déjà utilisé, libération...${NC}"
        kill $(lsof -t -i:$port) 2>/dev/null || true
        sleep 2
    fi
}

# Vérifier que le cluster est actif
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${YELLOW}⚠ Le cluster n'est pas accessible. Lancez d'abord ./start-cluster.sh${NC}"
    exit 1
fi

# Attendre que les pods soient prêts
echo -e "${YELLOW}⏳ Attente que les services soient prêts...${NC}"
kubectl wait --for=condition=Ready pods -n argocd -l app.kubernetes.io/name=argocd-server --timeout=120s 2>/dev/null || echo "ArgoCD pas encore prêt"
kubectl wait --for=condition=Ready pods -n online-boutique-dev -l app=frontend --timeout=120s 2>/dev/null || echo "Frontend pas encore prêt"

echo ""

# Libérer les ports si nécessaire
check_port 8080
check_port 8081

# Démarrer ArgoCD port-forward (8080)
echo -e "${GREEN}✓${NC} Port-forward ArgoCD sur ${BLUE}http://localhost:8080${NC}"
kubectl port-forward -n argocd svc/argocd-server 8080:443 > /tmp/argocd-pf.log 2>&1 &
ARGOCD_PID=$!

# Démarrer Online Boutique port-forward (8081)
echo -e "${GREEN}✓${NC} Port-forward Online Boutique sur ${BLUE}http://localhost:8081${NC}"
kubectl port-forward -n online-boutique-dev svc/frontend-external 8081:80 > /tmp/shop-pf.log 2>&1 &
SHOP_PID=$!

# Attendre que les port-forwards soient établis
sleep 3

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Services accessibles :${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  📊 ${BLUE}ArgoCD UI${NC}"
echo -e "     URL: ${YELLOW}https://localhost:8080${NC}"
echo -e "     User: ${YELLOW}admin${NC}"
echo -e "     Password: ${YELLOW}\$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath=\"{.data.password}\" | base64 -d)${NC}"
echo ""
echo -e "  🛒 ${BLUE}Online Boutique (DEV)${NC}"
echo -e "     URL: ${YELLOW}http://localhost:8081${NC}"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💡 Pour arrêter les port-forwards : Ctrl+C${NC}"
echo ""

# Fonction de nettoyage
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Arrêt des port-forwards...${NC}"
    kill $ARGOCD_PID 2>/dev/null || true
    kill $SHOP_PID 2>/dev/null || true
    echo -e "${GREEN}✓ Port-forwards arrêtés${NC}"
    exit 0
}

# Capturer Ctrl+C
trap cleanup INT TERM

# Afficher le mot de passe ArgoCD
echo -e "${BLUE}🔑 Mot de passe ArgoCD :${NC}"
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" 2>/dev/null | base64 -d
echo ""
echo ""

# Garder le script actif
echo -e "${YELLOW}⏳ Port-forwards actifs... (Ctrl+C pour arrêter)${NC}"
wait
