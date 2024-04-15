#!/bin/bash
#

set -eo pipefail

HELM_VERSION="v3.14.4"
HELM_BINARY="helm"
KIND_VERSION="v0.22.0"
KIND_BINARY="kind"
KIND_CLUSTER_CONFIG_FILE="spec/fixtures/kind-config.yaml"
KIND_CLUSTER_NAME="charts-passbolt-integration"
KUBECTL_BINARY="kubectl"
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
}

function createKindCluster {
	echo "Creating kind cluster: $KIND_CLUSTER_NAME"
	"$KIND_BINARY" create cluster --config "$KIND_CLUSTER_CONFIG_FILE" --name "$KIND_CLUSTER_NAME"
}

function createAndInstallSSLCertificates {
	domain="${1-passbolt.local}"
	ssl_key_path="$SSL_KEY_PATH"
	ssl_cert_path="$SSL_CERT_PATH"
	mkcert -install
	mkcert -cert-file "$ssl_cert_path" -key-file "$ssl_key_path" "$domain"
}

function createSecretWithTLS {
	secret_name="$K8S_LOCAL_TLS_SECRET"
	kubectl create secret tls $secret_name --cert="$ssl_cert_path" --key="$ssl_key_path"
}

function installNginxIngress {
	"$KUBECTL_BINARY" apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	"$KUBECTL_BINARY" rollout status deployment ingress-nginx-controller --timeout=120s -n ingress-nginx
}

function installPassboltChart {
	"$HELM_BINARY" install passbolt . -f ingress-values.yaml
	"$KUBECTL_BINARY" rollout status deployment passbolt-depl-srv --timeout=120s
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

installDependencies
createInfraAndInstallPassboltChart
