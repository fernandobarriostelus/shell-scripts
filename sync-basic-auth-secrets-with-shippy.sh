#!/bin/bash
set -o nounset -o errexit
cd "$(dirname "$0")"

shippy init
shippy login --silent

PASSWORD=$(shippy get secret http-preproduction-credentials --common --field=password | tr -d '\n' | base64)
USERNAME=$(shippy get secret http-preproduction-credentials --common --field=user | tr -d '\n' | base64)

# switch to non production environment in Kubernetes
gcloud container clusters get-credentials td-private-nane1-001-np --region northamerica-northeast1 --project td-digital-gke-private-np-b2fd

NAMESPACES=("koodo-commerce-shell" "sod-commerce-shell-telus" "koodo-checkout-shell" "sod-checkout-shell-telus")
for NAMESPACE in "${NAMESPACES[@]}"; do
    echo "Running for the namespace: $NAMESPACE"
    kubectl get secret basic-auth -n "$NAMESPACE" -o json |
        jq --arg PASSWORD "$PASSWORD" --arg USERNAME "$USERNAME" \
            '.data.password = $PASSWORD | .data.username = $USERNAME' |
        kubectl apply -f -
done

# switch to production environment in Kubernetes
gcloud container clusters get-credentials td-private-nane1-001-pr --region northamerica-northeast1 --project td-digital-gke-private-pr-d062

for NAMESPACE in "${NAMESPACES[@]}"; do
    kubectl get secret basic-auth -n "$NAMESPACE" -o json |
        jq --arg PASSWORD "$PASSWORD" --arg USERNAME "$USERNAME" \
            '.data.password = $PASSWORD | .data.username = $USERNAME' |
        kubectl apply -f -
done
