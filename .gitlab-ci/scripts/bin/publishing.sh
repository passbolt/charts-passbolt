#!/bin/sh

set -euo

# ENV
# REPO_BUCKET
# REPO_DIR
# CHART_NAME

HELM_GCS_PLUGIN_REPO="https://github.com/hayorov/helm-gcs.git"
REPO_NAME="passbolt"
REPO_URL="$REPO_BUCKET/$REPO_DIR/$CHART_NAME"
BUCKET_URL="$REPO_BUCKET.storage.googleapis.com/$REPO_DIR/$CHART_NAME"

source "$(dirname "$0")/../lib/helm.sh"

ensure_helm_plugin "gcs" "$HELM_GCS_PLUGIN_REPO"

index_code=$(curl -sk -o /dev/null -w '%{http_code}'  "https://$BUCKET_URL/index.yaml")

if [ "$index_code" == "404" ];
then
  echo "Creating new repository"
  helm gcs init "gs://$REPO_URL"
fi

helm package "."

helm repo add "$REPO_NAME" "gs://$REPO_URL"

helm gcs push "$CHART_NAME"-*.tgz "$REPO_NAME"
