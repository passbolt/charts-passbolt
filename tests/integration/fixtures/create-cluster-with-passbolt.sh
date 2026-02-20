#!/bin/bash
#

set -eo pipefail

DATABASE_ENGINE=mariadb
PROTOCOL=https
GPG_KEY_GENERATION=auto
KIND_CLUSTER_CONFIG_FILE="tests/integration/fixtures/kind-config.yaml"
KIND_CLUSTER_NAME="charts-passbolt-integration"
K8S_LOCAL_TLS_SECRET="local-tls-secret"
K8S_LOCAL_SERVER_GPG_KEY_SECRET="passbolt-server-gpg-key"
GPG_KEY_VALUES="/tmp/gpg-settings.yaml"
SSL_KEY_PATH="/tmp/ssl.key"
SSL_CERT_PATH="/tmp/ssl.crt"

function createKindCluster {
  echo "Creating kind cluster: ${KIND_CLUSTER_NAME}"
  "${KIND_BINARY}" create cluster --config "${KIND_CLUSTER_CONFIG_FILE}" --name "${KIND_CLUSTER_NAME}"
}

function installNginxIngress {
  "${KUBECTL_BINARY}" apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
  "${KUBECTL_BINARY}" rollout status deployment ingress-nginx-controller --timeout=200s -n ingress-nginx
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
  local helm_testing_values="tests/integration/fixtures/testing-${DATABASE_ENGINE}-${PROTOCOL}.yaml"
  local private_key=""
  local public_key=""
  local fingerprint=""
  local jwt_private_key=""
  local jwt_public_key=""
  local gpg_secret_name="passbolt-sec-gpg"
  if [[ ${GPG_KEY_GENERATION} == "existing_secret" ]]; then
    gpg_secret_name="${K8S_LOCAL_SERVER_GPG_KEY_SECRET}"
  fi
  private_key=$(kubectl get secret "${gpg_secret_name}" --namespace default -o jsonpath="{.data.serverkey_private\.asc}")
  public_key=$(kubectl get secret "${gpg_secret_name}" --namespace default -o jsonpath="{.data.serverkey\.asc}")
  fingerprint=$(kubectl exec deploy/passbolt-depl-srv -c passbolt-depl-srv -- grep PASSBOLT_GPG_SERVER_KEY_FINGERPRINT /etc/environment | awk -F= '{gsub(/"/, ""); print $2}')
  jwt_private_key=$(kubectl get secret passbolt-sec-jwt --namespace default -o jsonpath="{.data.jwt\.key}")
  jwt_public_key=$(kubectl get secret passbolt-sec-jwt --namespace default -o jsonpath="{.data.jwt\.pem}")
  "${HELM_BINARY}" upgrade -i passbolt . \
    -f "${helm_testing_values}" \
    -n default \
    --set integrationTests.debug="${DEBUG}" \
    --set integrationTests.rootless="${ROOTLESS}" \
    --set integrationTests.expected_gpg_fingerprint="${fingerprint}" \
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
  local helm_testing_values="tests/integration/fixtures/testing-${DATABASE_ENGINE}-${PROTOCOL}.yaml"
  local gpg_key_values="${GPG_KEY_VALUES}"
  if [[ -n "${GITLAB_CI}" || -n "${GITHUB_WORKFLOW}" ]]; then
    "${HELM_BINARY}" repo add bitnami https://charts.bitnami.com/bitnami
    "${HELM_BINARY}" repo add passbolt-library https://download.passbolt.com/charts/passbolt-library
    "${HELM_BINARY}" dependency build
  fi
  if "${HELM_BINARY}" status passbolt; then
    upgradePassboltChart
  else
    touch "${GPG_KEY_VALUES}"
    "${HELM_BINARY}" install passbolt . -f "${helm_testing_values}" -n default \
      -f "${GPG_KEY_VALUES}" \
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

function createGpgServerKeySecret {
  local gnupg_home=$(mktemp -d)
  local key_length=4096
  local email="passbolt@yourdomain.com"
  local gpg_private_key_path="${SERVER_PRIVATE_GPG_KEY_PATH}"
  local gpg_public_key_path="${SERVER_PUBLIC_GPG_KEY_PATH}"
  local gpg_key_values="${GPG_KEY_VALUES}"
  gpg --homedir ${gnupg_home} --batch --no-tty --gen-key <<EOF
    Key-Type: RSA
    Key-Length: $key_length
    Key-Usage: sign,cert
    Subkey-Type: RSA
    Subkey-Length: $key_length
    Subkey-Usage: encrypt
    Name-Real: Passbolt default user
    Name-Email: $email
    Expire-Date: 0
    %no-protection
    %commit
EOF
  local gpg_private_key=$(gpg --homedir "${gnupg_home}" --batch --armor --export-secret-keys "${email}")
  local gpg_public_key=$(gpg --homedir "${gnupg_home}" --armor --export "${email}")
  local gpg_fingerprint=$(gpg --homedir "${gnupg_home}" --with-colons --fingerprint "${email}" | awk -F: '/^pub:/ { getline; print $10}')
  if [[ ${GPG_KEY_GENERATION} == "provided" ]]; then
    cat << EOF > ${gpg_key_values}
integrationTests:
    expected_gpg_fingerprint: "${gpg_fingerprint}"
gpgServerKeyPrivate: $(echo "${gpg_private_key}" | base64 -w 0)
gpgServerKeyPublic: $(echo "${gpg_public_key}" | base64 -w 0)
EOF
  elif [[ ${GPG_KEY_GENERATION} == "existing_secret" ]]; then
    local secret_name="${K8S_LOCAL_SERVER_GPG_KEY_SECRET}"
    if "${KUBECTL_BINARY}" get secret ${secret_name} -n default &>/dev/null; then
      "${KUBECTL_BINARY}" delete secret ${secret_name} -n default
    fi
    "${KUBECTL_BINARY}" create secret generic ${secret_name} --from-literal=serverkey_private.asc="${gpg_private_key}" --from-literal=serverkey.asc="${gpg_public_key}" -n default
    cat << EOF > ${gpg_key_values}
integrationTests:
    expected_gpg_fingerprint: "${gpg_fingerprint}"
gpgExistingSecret: "${secret_name}"
EOF
  fi
}

function createInfraAndInstallPassboltChart {
  if ! "${KUBECTL_BINARY}" config view -o jsonpath='{.contexts[*].name}' | grep -q "${KIND_CLUSTER_NAME}"; then
    createKindCluster
    createAndInstallSSLCertificates
    createSecretWithTLS
    installNginxIngress
    if [[ $GPG_KEY_GENERATION != "auto" ]]; then
      createGpgServerKeySecret
    fi
    installPassboltChart
  else
    echo "Cluster ${KIND_CLUSTER_NAME} already exists"
  fi
}

while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    showHelp
    ;;
  -d | --database)
    shift
    DATABASE_ENGINE=$1
    shift
    ;;
  -p | --protocol)
    shift
    PROTOCOL=$1
    shift
    ;;
  -g | --gpg)
    shift
    GPG_KEY_GENERATION=$1
    shift
    ;;
  *)
    echo "Unknown argurment $1"
    exit 1
    ;;
  esac
done

createInfraAndInstallPassboltChart
