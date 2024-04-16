#!/bin/bash
#

set -eo pipefail

HELM_VERSION="v3.14.4"
HELM_BINARY="helm"
KIND_VERSION="v0.19.0" # 0.19 because the new ones fail on .gitlab-ci
KIND_BINARY="kind"
KIND_CLUSTER_CONFIG_FILE="spec/fixtures/kind-config.yaml"
KIND_CLUSTER_NAME="charts-passbolt-integration"
KUBECTL_BINARY="kubectl"
MKCERT_BINARY="mkcert"
K8S_LOCAL_TLS_SECRET="local-tls-secret"
PASSBOLT_CLI_BINARY="passbolt"
PASSBOLT_CLI_VERSION="0.3.1"
SSL_KEY_PATH="/tmp/ssl.key"
SSL_CERT_PATH="/tmp/ssl.crt"

function getKubectl {
	if ! command -v "$KUBECTL_BINARY" >/dev/null; then
		curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
		chmod +x kubectl
		KUBECTL_BINARY="./kubectl"
	fi
}

function getKind {
	if ! command -v "$KIND_BINARY" >/dev/null; then
		curl -Lo ./kind "https://kind.sigs.k8s.io/dl/$KIND_VERSION/kind-linux-amd64"
		chmod +x kind
		KIND_BINARY="./kind"
	fi
}

function getHelm {
	if ! command -v "$HELM_BINARY" >/dev/null; then
		curl -sL "https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz" >/tmp/helm.gz
		tar -xvf /tmp/helm.gz linux-amd64/helm && mv linux-amd64/helm . && rmdir linux-amd64
		HELM_BINARY="./helm"
	fi
}

function getMkcert {
	if ! command -v "$MKCERT_BINARY" >/dev/null; then
		echo "Installing mkcert..."
		curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
		chmod +x mkcert-v*-linux-amd64
		mv mkcert-v*-linux-amd64 mkcert
		MKCERT_BINARY="./mkcert"
	fi
}

function getPassboltGoCli {
	if ! command -v "$PASSBOLT_CLI_BINARY" >/dev/null; then
		version="$PASSBOLT_CLI_VERSION"
		curl -sL "https://github.com/passbolt/go-passbolt-cli/releases/download/v${version}/go-passbolt-cli_${version}_linux_amd64.tar.gz" >/tmp/cli.tar.gz
		tar -xvf /tmp/cli.tar.gz passbolt
		PASSBOLT_CLI_BINARY="./passbolt"
	fi
}

function installDependencies {
	getKind
	getKubectl
	getHelm
	getMkcert
	getPassboltGoCli
	echo "$KUBECTL_BINARY"
	echo "$HELM_BINARY"
	echo "$MKCERT_BINARY"
	echo "$PASSBOLT_CLI_BINARY"
	echo "$KIND_BINARY"
}

function createKindCluster {
	echo "Creating kind cluster: $KIND_CLUSTER_NAME"
	"$KIND_BINARY" create cluster --config "$KIND_CLUSTER_CONFIG_FILE" --name "$KIND_CLUSTER_NAME"
}

function createAndInstallSSLCertificates {
	domain="${1-passbolt.local}"
	ssl_key_path="$SSL_KEY_PATH"
	ssl_cert_path="$SSL_CERT_PATH"
	"$MKCERT_BINARY" -install
	ls -lash
	"$MKCERT_BINARY" -cert-file "$ssl_cert_path" -key-file "$ssl_key_path" "$domain"
	echo despois
	ls -lash
}

function createSecretWithTLS {
	secret_name="$K8S_LOCAL_TLS_SECRET"
	echo "$KUBECTL_BINARY" create secret tls $secret_name --cert="$ssl_cert_path" --key="$ssl_key_path" -n default
	"$KUBECTL_BINARY" create secret tls $secret_name --cert="$ssl_cert_path" --key="$ssl_key_path" -n default
}

function installNginxIngress {
	"$KUBECTL_BINARY" apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	"$KUBECTL_BINARY" rollout status deployment ingress-nginx-controller --timeout=120s -n ingress-nginx
}

function installPassboltChart {
	if [[ ! -z "$GITLAB_CI" ]]; then
		"$HELM_BINARY" repo add bitnami https://charts.bitnami.com/bitnami
		"$HELM_BINARY" repo add passbolt-library https://download.passbolt.com/charts/passbolt-library
		"$HELM_BINARY" dependency build
	fi
	"$HELM_BINARY" install passbolt . -f ingress-values.yaml -n default
	"$KUBECTL_BINARY" rollout status deployment passbolt-depl-srv --timeout=120s -n default
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

#installDependencies
#createInfraAndInstallPassboltChart
