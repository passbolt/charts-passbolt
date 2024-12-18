#!/bin/bash

HELM_VERSION="v3.14.4"
HELM_BINARY="helm"
KIND_VERSION="v0.19.0" # 0.19 because the new ones fail on .gitlab-ci
KIND_BINARY="kind"
KUBECTL_BINARY="kubectl"
MKCERT_BINARY="mkcert"
PASSBOLT_CLI_BINARY="passbolt"
PASSBOLT_CLI_VERSION="0.3.1"
PASSBOLT_FQDN=passbolt.local
SSL_KEY_PATH="/tmp/ssl.key"
SSL_CERT_PATH="/tmp/ssl.crt"

function getKubectl {
  local path="./kubectl"
  if ! command -v "${KUBECTL_BINARY}" >/dev/null && [ ! -f "${path}" ]; then
    curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum -c
    chmod +x kubectl
    KUBECTL_BINARY="./kubectl"
  fi
}

function getKind {
  local path="./kind"
  if ! command -v "${KIND_BINARY}" >/dev/null && [ ! -f "${path}" ]; then
    curl -sLo ./kind-linux-amd64 "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
    curl -sLo ./kind-sha256sum "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64.sha256sum"
    sha256sum -c kind-sha256sum
    mv kind-linux-amd64 kind && chmod +x kind && rm kind-sha256sum
    KIND_BINARY="./kind"
  fi
}

function getHelm {
  local path="./helm"
  if ! command -v "${HELM_BINARY}" >/dev/null && [ ! -f "${path}" ]; then
    curl -sL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" >helm-"${HELM_VERSION}"-linux-amd64.tar.gz
    curl -sL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz.sha256sum" >helm.sha256sum
    sha256sum -c helm.sha256sum
    tar -xvf helm-"${HELM_VERSION}"-linux-amd64.tar.gz linux-amd64/helm && mv linux-amd64/helm . && rm -rf linux-amd64 helm-"${HELM_VERSION}"-linux-amd64.tar.gz helm.sha256sum
    HELM_BINARY="./helm"
  fi
}

function getMkcert {
  local path="./mkcert"
  if ! command -v "${MKCERT_BINARY}" >/dev/null && [ ! -f "${path}" ]; then
    echo "Installing mkcert..."
    curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
    chmod +x mkcert-v*-linux-amd64
    mv mkcert-v*-linux-amd64 mkcert
    MKCERT_BINARY="./mkcert"
  fi
}

function getPassboltGoCli {
  local path="./passbolt"
  if ! command -v "${PASSBOLT_CLI_BINARY}" >/dev/null && [ ! -f "${path}" ]; then
    local version="${PASSBOLT_CLI_VERSION}"
    curl -sL "https://github.com/passbolt/go-passbolt-cli/releases/download/v${version}/go-passbolt-cli_${version}_linux_amd64.tar.gz" >go-passbolt-cli_"${version}"_linux_amd64.tar.gz
    curl -sL "https://github.com/passbolt/go-passbolt-cli/releases/download/v${version}/checksums.txt" | grep "${version}_linux_amd64.tar.gz" >cli.sha256sum
    sha256sum -c cli.sha256sum
    tar -xvf go-passbolt-cli_"${version}"_linux_amd64.tar.gz passbolt >/dev/null && rm cli.sha256sum go-passbolt-cli_"${version}"_linux_amd64.tar.gz
    PASSBOLT_CLI_BINARY="./passbolt"
  fi
}

function addHostsEntry {
  echo "Adding hosts entry to ingress cluster ip..."
  echo "$("${KUBECTL_BINARY}" get service/ingress-nginx-controller -o jsonpath='{.spec.clusterIP}' -n ingress-nginx) ${PASSBOLT_FQDN}" >>/etc/hosts
}

function installDependencies {
  getKind
  getKubectl
  getHelm
  getMkcert
  getPassboltGoCli
  export KUBECTL_BINARY="${KUBECTL_BINARY}"
  export HELM_BINARY="${HELM_BINARY}"
  export MKCERT_BINARY="${MKCERT_BINARY}"
  export PASSBOLT_CLI_BINARY="${PASSBOLT_CLI_BINARY}"
  export KIND_BINARY="${KIND_BINARY}"
}
