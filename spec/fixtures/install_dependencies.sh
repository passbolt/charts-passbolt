#!/bin/bash

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
		tar -xvf /tmp/cli.tar.gz passbolt >/dev/null
		PASSBOLT_CLI_BINARY="./passbolt"
	fi
}

function installDependencies {
	getKind
	getKubectl
	getHelm
	getMkcert
	getPassboltGoCli
	export KUBECTL_BINARY="$KUBECTL_BINARY"
	export HELM_BINARY="$HELM_BINARY"
	export MKCERT_BINARY="$MKCERT_BINARY"
	export PASSBOLT_CLI_BINARY="$PASSBOLT_CLI_BINARY"
	export KIND_BINARY="$KIND_BINARY"
}

installDependencies
