#!/bin/bash

# Script de déploiement Online Boutique GitOps
# Usage: ./deploy.sh [dev|prod|all]

set -e

ENVIRONMENT=${1:-all}

echo "🚀 Déploiement Online Boutique GitOps"
echo "Environnement: $ENVIRONMENT"

# Vérification des prérequis
check_prerequisites() {
    echo "🔍 Vérification des prérequis..."
    
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl n'est pas installé"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        echo "❌ Pas de connexion au cluster Kubernetes"
        exit 1
    fi
    
    echo "✅ Prérequis OK"
}

# Déploiement environnement dev
deploy_dev() {
    echo "🔧 Déploiement environnement DEV..."
    kubectl apply -k argocd/dev
    echo "✅ Applications DEV déployées"
}

# Déploiement environnement prod
deploy_prod() {
    echo "🔧 Déploiement environnement PROD..."
    kubectl apply -k argocd/prod
    echo "✅ Applications PROD déployées"
}

# Vérification du déploiement
check_deployment() {
    local env=$1
    echo "🔍 Vérification du déploiement $env..."
    
    # Attendre que les applications ArgoCD soient créées
    sleep 5
    
    echo "Applications ArgoCD:"
    kubectl get applications -n argocd | grep "$env-"
    
    echo "Pods $env:"
    kubectl get pods -n "online-boutique-$env" 2>/dev/null || echo "Namespace pas encore créé"
}

# Fonction principale
main() {
    check_prerequisites
    
    case $ENVIRONMENT in
        "dev")
            deploy_dev
            check_deployment "dev"
            ;;
        "prod")
            deploy_prod
            check_deployment "prod"
            ;;
        "all")
            deploy_dev
            deploy_prod
            check_deployment "dev"
            check_deployment "prod"
            ;;
        *)
            echo "❌ Environnement invalide. Usage: $0 [dev|prod|all]"
            exit 1
            ;;
    esac
    
    echo ""
    echo "🎉 Déploiement terminé!"
    echo ""
    echo "Pour accéder à l'application:"
    echo "  Dev:  kubectl port-forward -n online-boutique-dev svc/frontend-online-boutique-service 8080:8080"
    echo "  Prod: kubectl port-forward -n online-boutique-prod svc/frontend-online-boutique-service 8081:8080"
    echo ""
    echo "Pour accéder à ArgoCD:"
    echo "  kubectl port-forward svc/argocd-server -n argocd 8082:443"
    echo "  URL: https://localhost:8082"
    echo "  Username: admin"
    echo "  Password: 3H-sejo-MRftTQTu"
}

main