#!/bin/bash
#

set -eo pipefail

KIND_CLUSTER_CONFIG_FILE="tests/integration/fixtures/kind-config.yaml"
HELM_TESTING_VALUES="tests/integration/fixtures/testing.yaml"
KIND_CLUSTER_NAME="charts-passbolt-integration"
K8S_LOCAL_TLS_SECRET="local-tls-secret"
SSL_KEY_PATH="/tmp/ssl.key"
SSL_CERT_PATH="/tmp/ssl.crt"

function createKindCluster {
	echo "Creating kind cluster: $KIND_CLUSTER_NAME"
	"$KIND_BINARY" create cluster --config "$KIND_CLUSTER_CONFIG_FILE" --name "$KIND_CLUSTER_NAME"
}

function installNginxIngress {
	"$KUBECTL_BINARY" apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	"$KUBECTL_BINARY" rollout status deployment ingress-nginx-controller --timeout=120s -n ingress-nginx
}

function installPassboltChart {
	if [[ ! -z "$GITLAB_CI" || ! -z "$GITHUB_WORKFLOW" ]]; then
		"$HELM_BINARY" repo add bitnami https://charts.bitnami.com/bitnami
		"$HELM_BINARY" repo add passbolt-library https://download.passbolt.com/charts/passbolt-library
		"$HELM_BINARY" dependency build
	fi
	"$HELM_BINARY" install passbolt . -f $HELM_TESTING_VALUES -n default --set integrationTests.debug="$DEBUG"
	"$KUBECTL_BINARY" rollout status deployment passbolt-depl-srv --timeout=120s -n default
}

function createAndInstallSSLCertificates {
	local domain="${1-passbolt.local}"
	local ssl_key_path="$SSL_KEY_PATH"
	local ssl_cert_path="$SSL_CERT_PATH"
	"$MKCERT_BINARY" -install
	"$MKCERT_BINARY" -cert-file "$ssl_cert_path" -key-file "$ssl_key_path" "$domain"
	"$KUBECTL_BINARY" create secret generic mkcert-ca \
		--from-file=rootCA-key.pem=$("$MKCERT_BINARY" -CAROOT)/rootCA-key.pem \
		--from-file=rootCA.pem=$("$MKCERT_BINARY" -CAROOT)/rootCA.pem \
		-n default
}

function createSecretWithTLS {
	local secret_name="$K8S_LOCAL_TLS_SECRET"
	local ssl_key_path="$SSL_KEY_PATH"
	local ssl_cert_path="$SSL_CERT_PATH"
	if "$KUBECTL_BINARY" get secret $secret_name -n default &>/dev/null; then
		"$KUBECTL_BINARY" delete secret $secret_name -n default
	fi
	"$KUBECTL_BINARY" create secret tls $secret_name --cert="$ssl_cert_path" --key="$ssl_key_path" -n default
}
function createInfraAndInstallPassboltChart {
	if ! "$KUBECTL_BINARY" config view -o jsonpath='{.contexts[*].name}' | grep -q "$KIND_CLUSTER_NAME"; then
		createKindCluster
		createAndInstallSSLCertificates
		createSecretWithTLS
		installNginxIngress
		installPassboltChart
	else
		echo "Cluster $KIND_CLUSTER_NAME already exists"
	fi
}

createInfraAndInstallPassboltChart
