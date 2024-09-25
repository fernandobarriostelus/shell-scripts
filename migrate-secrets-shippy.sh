#!/usr/bin/env bash

set -o nounset -o errexit

# Parse input arguments
OLD_ENV_PROJECT=${1:-""}
NEW_ENV_PROJECT=${2:-""}

# Split environment and project
IFS='/' read -r OLD_ENV OLD_PROJECT <<<"$OLD_ENV_PROJECT"
IFS='/' read -r NEW_ENV NEW_PROJECT <<<"$NEW_ENV_PROJECT"

# Split environment and project
IFS='/' read -r OLD_ENV OLD_PROJECT <<<"$OLD_ENV_PROJECT"
IFS='/' read -r NEW_ENV NEW_PROJECT <<<"$NEW_ENV_PROJECT"

if ! command -v shippy &>/dev/null; then
    npm i -g @telus/shippy-cli
fi

if [[ $OLD_PROJECT == "" || $OLD_ENV == "" || $NEW_PROJECT == "" || $NEW_ENV == "" ]]; then
    echo
    echo "Usage: migrate-secrets-shippy.sh <old-environment>/<old-project> <new-environment>/<new-project>"
    echo
    exit 1
fi

echo
echo "old environment: $OLD_ENV"
echo "old project: $OLD_PROJECT"
echo "new environment: $NEW_ENV"
echo "new project: $NEW_PROJECT"
echo

shippy login --silent

# switch to old environment and project
shippy environment "$OLD_ENV"
shippy project "$OLD_PROJECT"

# get all secrets and output to temp yaml files
SECRET_NAMES=$(shippy get secrets)
for SECRET_NAME in ${SECRET_NAMES}; do
    echo "Getting secret ${SECRET_NAME}"
    shippy get secret "${SECRET_NAME}" >"${SECRET_NAME}".yaml
    echo
done

# switch to new environment and project
shippy environment "$NEW_ENV"
shippy project "$NEW_PROJECT"

# create/update all secrets
for SECRET_NAME in ${SECRET_NAMES}; do
    echo "Creating/updating secret ${SECRET_NAME}"
    if ! shippy create secret "$SECRET_NAME" -f "${SECRET_NAME}".yaml; then
        continue
    fi
    rm "${SECRET_NAME}".yaml
    echo
done
