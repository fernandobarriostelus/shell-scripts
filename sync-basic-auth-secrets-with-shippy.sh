#!/bin/bash
set -o nounset -o errexit
cd "$(dirname "$0")"

shippy init
shippy login --silent

PASSWORD=$(shippy get secret http-preproduction-credentials --common --field=password | tr -d '\n' | base64)
USERNAME=$(shippy get secret http-preproduction-credentials --common --field=user | tr -d '\n' | base64)

update_secrets() {
    local cluster=$1
    local region=$2
    local project=$3
    local namespaces=("${!4}")

    # switch to the specified environment in Kubernetes
    gcloud container clusters get-credentials "$cluster" --region "$region" --project "$project"

    for NAMESPACE in "${namespaces[@]}"; do
        echo "Updating secret in namespace $NAMESPACE"
        kubectl get secret basic-auth -n "$NAMESPACE" -o json |
            jq --arg PASSWORD "$PASSWORD" --arg USERNAME "$USERNAME" \
                '.data.password = $PASSWORD | .data.username = $USERNAME' |
            kubectl apply -f -

        # Get the names of all deployments in the namespace
        DEPLOYMENTS=$(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')

        # Restart each deployment
        for DEPLOYMENT in $DEPLOYMENTS; do
            echo "Restarting deployment $DEPLOYMENT"
            # This subcommand is used to restart the pods managed by a deployment.
            # It triggers a rolling restart of the deployment, which means the pods
            # will be restarted one by one to ensure minimal downtime.
            kubectl rollout restart deployment "$DEPLOYMENT" -n "$NAMESPACE"
        done

    done
}

NAMESPACES=("koodo-commerce-shell" "sod-commerce-shell-telus" "koodo-checkout-shell" "sod-checkout-shell-telus")

# Update secrets in non-production environment
update_secrets "td-private-nane1-001-np" "northamerica-northeast1" "td-digital-gke-private-np-b2fd" NAMESPACES[@]

# Update secrets in production environment
update_secrets "td-private-nane1-001-pr" "northamerica-northeast1" "td-digital-gke-private-pr-d062" NAMESPACES[@]
