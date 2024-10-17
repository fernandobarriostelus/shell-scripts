#!/bin/bash
set -o nounset -o errexit
cd "$(dirname "$0")"

JIRA_USER_EMAIL=
JIRA_API_TOKEN=

update_secrets() {
    local PROJECTS=("${!1}")

    for PROJECT in "${PROJECTS[@]}"; do
        GH_PROJECT="telus/${PROJECT}"
        echo "Updating secret in project: $GH_PROJECT"
        gh secret set JIRA_USER_EMAIL --body "$JIRA_USER_EMAIL" -a actions -R "$GH_PROJECT"
        gh secret set JIRA_API_TOKEN --body "$JIRA_API_TOKEN" -a actions -R "$GH_PROJECT"
    done
}

PROJECTS=(

    # Commerce & Checkout Repositories
    "koodo-checkout-shell"
    "koodo-commerce-shell"
    "address-selection-mfe"
    "sod-api-kit"
    "sod-session-api"
    "koodo-header-footer-mfe"

    # Manage Repositories
    "product-subscription-overview-mfe"
    "appointment-selection-mfe"
    "sod-cancel-renew-mfe"
    "sod-receipts-mfe"
    "sod-receipts-mfe-inspire"
    "sod-payments-mfe"
    "sod-payments-bff"
)

update_secrets PROJECTS[@]
