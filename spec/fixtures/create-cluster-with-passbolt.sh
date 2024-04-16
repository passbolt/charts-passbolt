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
	"$KUBECTL_BINARY" rollout status deployment passbolt-depl-srv --timeout=120s -n defaultfixfix
}

function addEtcHostsEntry {
	echo "127.0.0.1 $PASSBOLT_FQDN" >>/etc/hosts
}

function createInfraAndInstallPassboltChart {
	if ! "$KUBECTL_BINARY" config view -o jsonpath='{.contexts[*].name}' | grep -q "$KIND_CLUSTER_NAME"; then
		createKindCluster
		createAndInstallSSLCertificates
		createSecretWithTLS
		installNginxIngress
		installPassboltChart
		addEtcHostsEntry
	else
		echo "Cluster $KIND_CLUSTER_NAME already exists"
	fi
}

createInfraAndInstallPassboltChart
