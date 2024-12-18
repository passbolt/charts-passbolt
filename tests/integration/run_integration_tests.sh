#!/bin/bash

set -eo pipefail

SPECS_DIR=$(dirname "${0}")

source "${SPECS_DIR}"/fixtures/gpg.sh
source "${SPECS_DIR}"/fixtures/passbolt.sh
source "${SPECS_DIR}"/fixtures/log.sh
source "${SPECS_DIR}"/fixtures/install_dependencies.sh
source <(cat "${SPECS_DIR}"/tests/*_test.sh)

TMPGNUPGHOME=$(mktemp -d)
PASSPHRASE="strong-passphrase"
PASSBOLT_FQDN=passbolt.local
#EMAIL="email$(date +'%s')@domain.tld"
FIRSTNAME="John"
LASTNAME="Doe"
declare -a DEBUG_MESSAGES

function testRunner {
  name="$(echo "$@" | cut -d : -f 1)"
  description="$(echo "$@" | cut -d : -f 2)"
  green_text="\033[0;32m"
  red_text="\033[0;31m"
  reset="\033[0m"
  log_file="/tmp/${name}-integration-tests.log"
  if ${name} &>"${log_file}"; then
    _echo
    echo -e "${green_text}[PASS] ${description}${reset}"
  else
    _echo
    echo -e "${red_text}[FAIL] ${description}${reset}"
    cat "${log_file}"
    return 1
  fi
}

installDependencies
echo Waiting for redis to be ready...
"${KUBECTL_BINARY}" wait pod -l app.kubernetes.io/name=redis --for=condition=Ready
# install CA from secret values
CAROOT=/mkcert "${MKCERT_BINARY}" -install
addHostsEntry

list=(
  "testCreateAndDecryptPassword:It_should_create_and_decrypt_a_password"
  "testCreateAndRemovePassword:It_should_create_and_remove_a_password"
  "testCreateShareAndDecryptPassword:It_should_create_share_and_decrypt_a_password"
  "testCreateAndFillFolder:It_should_create_and_fill_a_folder_with_passwords"
)
failed=false
for name in "${list[@]}"; do
  if ! testRunner "${name}"; then
    failed=true
  fi
done

if [ ${failed} == true ]; then
  exit 1
fi
