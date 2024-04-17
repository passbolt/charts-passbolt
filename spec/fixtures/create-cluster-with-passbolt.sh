#!/bin/bash
#

set -eo pipefail

source $(dirname $0)/install_dependencies.sh

SSL_KEY_PATH="/tmp/ssl.key"
SSL_CERT_PATH="/tmp/ssl.crt"
PASSBOLT_FQDN=passbolt.local

function createKindCluster {
	echo "Creating kind cluster: $KIND_CLUSTER_NAME"
	"$KIND_BINARY" create cluster --config "$KIND_CLUSTER_CONFIG_FILE" --name "$KIND_CLUSTER_NAME"
}

function installNginxIngress {
	"$KUBECTL_BINARY" apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	"$KUBECTL_BINARY" rollout status deployment ingress-nginx-controller --timeout=120s -n ingress-nginx
}

function installPassboltChart {
	if [[ ! -z "$GITLAB_CI" && ! -z "$GITHUB_WORKFLOW" ]]; then
		"$HELM_BINARY" repo add bitnami https://charts.bitnami.com/bitnami
		"$HELM_BINARY" repo add passbolt-library https://download.passbolt.com/charts/passbolt-library
		"$HELM_BINARY" dependency build
	fi
	"$HELM_BINARY" install passbolt . -f ingress-values.yaml -n default --set enableIntegrationTests=true
	"$KUBECTL_BINARY" rollout status deployment passbolt-depl-srv --timeout=120s -n default
}

function createInfraAndInstallPassboltChart {
	if ! "$KUBECTL_BINARY" config view -o jsonpath='{.contexts[*].name}' | grep -q "$KIND_CLUSTER_NAME"; then
		createKindCluster
		createAndInstallSSLCertificates
		createSecretWithTLS
		installNginxIngress
		installPassboltChart
		#addEtcHostsEntry
	else
		echo "Cluster $KIND_CLUSTER_NAME already exists"
	fi
}

installDependencies
createInfraAndInstallPassboltChart
