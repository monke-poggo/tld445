# Helm Values Configuration

## Structure

Ce dossier contient les configurations Helm values pour les différents environnements :

- `dev/` - Configuration pour l'environnement de développement
- `prod/` - Configuration pour l'environnement de production

## Services configurés

### Microservices Online Boutique

1. **frontend** - Interface utilisateur (port 8080)
2. **adservice** - Service de publicités (port 9555)
3. **cartservice** - Service de panier (port 7070)
4. **checkoutservice** - Service de commande (port 5050)
5. **currencyservice** - Service de devises (port 7000)
6. **emailservice** - Service d'email (port 5000)
7. **paymentservice** - Service de paiement (port 50051)
8. **productcatalogservice** - Catalogue produits (port 3550)
9. **recommendationservice** - Service de recommandations (port 8080)
10. **shippingservice** - Service de livraison (port 50051)
11. **redis** - Cache Redis (port 6379)

## Utilisation

Pour déployer un service avec Helm :

```bash
# Déploiement en dev
helm install frontend ./charts -f helm-values/dev/frontend.yaml

# Déploiement en prod
helm install frontend ./charts -f helm-values/prod/frontend.yaml
```

## Corrections apportées

1. **Chart.yaml** - Ajout des métadonnées du chart
2. **_helpers.tpl** - Ajout des fonctions de template Helm
3. **Templates** - Correction des références aux ports et labels
4. **Values** - Standardisation de la structure et ajout des probes
5. **Variables d'environnement** - Correction du format (objet au lieu de tableau)
6. **Ports** - Correction des incohérences entre services
7. **Health checks** - Ajout des probes appropriées (HTTP/gRPC/TCP)