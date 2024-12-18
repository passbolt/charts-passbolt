#!/bin/bash
#

set -eo pipefail

DATABASE_ENGINE="${1:-mariadb}"
KIND_CLUSTER_CONFIG_FILE="tests/integration/fixtures/kind-config.yaml"
HELM_TESTING_VALUES="tests/integration/fixtures/testing-${DATABASE_ENGINE}.yaml"
KIND_CLUSTER_NAME="charts-passbolt-integration"
K8S_LOCAL_TLS_SECRET="local-tls-secret"
SSL_KEY_PATH="/tmp/ssl.key"
SSL_CERT_PATH="/tmp/ssl.crt"

function createKindCluster {
  echo "Creating kind cluster: ${KIND_CLUSTER_NAME}"
  "${KIND_BINARY}" create cluster --config "${KIND_CLUSTER_CONFIG_FILE}" --name "${KIND_CLUSTER_NAME}"
}

function installNginxIngress {
  "${KUBECTL_BINARY}" apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
  "${KUBECTL_BINARY}" rollout status deployment ingress-nginx-controller --timeout=120s -n ingress-nginx
}

function http_port {
  if [ "${ROOTLESS}" == true ]; then
    echo 8080
  else
    echo 80
  fi
}

function https_port {
  if [ "${ROOTLESS}" == true ]; then
    echo 4433
  else
    echo 443
  fi
}

function image_tag {
  tag="$(awk -F ' ' '/^    tag:/ {print $2}' values.yaml)"
  if [ "${ROOTLESS}" == true ]; then
    echo "${tag}"-non-root
  else
    echo "${tag}"
  fi
}

function upgradePassboltChart {
  local private_key=""
  local public_key=""
  local fingerprint=""
  local jwt_private_key=""
  local jwt_public_key=""
  private_key=$(kubectl get secret passbolt-sec-gpg --namespace default -o jsonpath="{.data.serverkey_private\.asc}")
  public_key=$(kubectl get secret passbolt-sec-gpg --namespace default -o jsonpath="{.data.serverkey\.asc}")
  fingerprint=$(kubectl exec deploy/passbolt-depl-srv -c passbolt-depl-srv -- grep PASSBOLT_GPG_SERVER_KEY_FINGERPRINT /etc/environment | awk -F= '{gsub(/"/, ""); print $2}')
  jwt_private_key=$(kubectl get secret passbolt-sec-jwt --namespace default -o jsonpath="{.data.jwt\.key}")
  jwt_public_key=$(kubectl get secret passbolt-sec-jwt --namespace default -o jsonpath="{.data.jwt\.pem}")
  "${HELM_BINARY}" upgrade -i passbolt . \
    -f "${HELM_TESTING_VALUES}" \
    -n default \
    --set integrationTests.debug="${DEBUG}" \
    --set integrationTests.rootless="${ROOTLESS}" \
    --set app.image.tag="$(image_tag)" \
    --set gpgServerKeyPrivate="${private_key}" \
    --set gpgServerKeyPublic="${public_key}" \
    --set passboltEnv.secret.PASSBOLT_GPG_SERVER_KEY_FINGERPRINT="${fingerprint}" \
    --set jwtServerPrivate="${jwt_private_key}" \
    --set jwtServerPublic="${jwt_public_key}" \
    --set service.ports.https.targetPort="$(https_port)" \
    --set service.ports.http.targetPort="$(http_port)"
}

function installPassboltChart {
  if [[ -n "${GITLAB_CI}" || -n "${GITHUB_WORKFLOW}" ]]; then
    "${HELM_BINARY}" repo add bitnami https://charts.bitnami.com/bitnami
    "${HELM_BINARY}" repo add passbolt-library https://download.passbolt.com/charts/passbolt-library
    "${HELM_BINARY}" dependency build
  fi
  if "${HELM_BINARY}" status passbolt; then
    upgradePassboltChart
  else
    "${HELM_BINARY}" install passbolt . -f "${HELM_TESTING_VALUES}" -n default \
      --set service.ports.https.targetPort="$(https_port)" \
      --set service.ports.http.targetPort="$(http_port)" \
      --set app.image.tag="$(image_tag)" \
      --set integrationTests.debug="${DEBUG}" \
      --set integrationTests.rootless="${ROOTLESS}"
  fi
  "${KUBECTL_BINARY}" rollout status deployment passbolt-depl-srv --timeout=120s -n default
}

function createAndInstallSSLCertificates {
  local domain="passbolt.local"
  local ssl_key_path="${SSL_KEY_PATH}"
  local ssl_cert_path="${SSL_CERT_PATH}"
  "${MKCERT_BINARY}" -install
  "${MKCERT_BINARY}" -cert-file "${ssl_cert_path}" -key-file "${ssl_key_path}" "${domain}"
  "${KUBECTL_BINARY}" create secret generic mkcert-ca \
    --from-file=rootCA-key.pem="$(${MKCERT_BINARY} -CAROOT)"/rootCA-key.pem \
    --from-file=rootCA.pem="$(${MKCERT_BINARY} -CAROOT)"/rootCA.pem \
    -n default
}

function createSecretWithTLS {
  local secret_name="${K8S_LOCAL_TLS_SECRET}"
  local ssl_key_path="${SSL_KEY_PATH}"
  local ssl_cert_path="${SSL_CERT_PATH}"
  if "${KUBECTL_BINARY}" get secret ${secret_name} -n default &>/dev/null; then
    "${KUBECTL_BINARY}" delete secret ${secret_name} -n default
  fi
  "${KUBECTL_BINARY}" create secret tls ${secret_name} --cert="${ssl_cert_path}" --key="${ssl_key_path}" -n default
}
function createInfraAndInstallPassboltChart {
  if ! "${KUBECTL_BINARY}" config view -o jsonpath='{.contexts[*].name}' | grep -q "${KIND_CLUSTER_NAME}"; then
    createKindCluster
    createAndInstallSSLCertificates
    createSecretWithTLS
    installNginxIngress
    installPassboltChart
  else
    echo "Cluster ${KIND_CLUSTER_NAME} already exists"
  fi
}

createInfraAndInstallPassboltChart
