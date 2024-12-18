#!/bin/bash

function registerPassboltUser {
  local firstname=${1}
  local lastname=${2}
  local email=${3}
  # This string must remain with single quotes as it is used as a command in line 12/14
  local register_command='bin/cake passbolt register_user -u $0 -f $1 -l $2 -r admin'
  #local command_as_root="su -c "$register_command" -- $email $firstname $lastname -s /bin/bash www-data"
  #local command_as_www="bash -c "$register_command" -- $email $firstname $lastname"
  if [ "${ROOTLESS}" == true ]; then
    registration=$("${KUBECTL_BINARY}" exec -it deployment/passbolt-depl-srv -n default -- bash -c "${register_command}" "${email}" "${firstname}" "${lastname}" 2>/dev/null)
  else
    registration=$("${KUBECTL_BINARY}" exec -it deployment/passbolt-depl-srv -n default -- su www-data -c "${register_command}" "${email}" "${firstname}" "${lastname}" -s /bin/bash 2>/dev/null)
  fi
  _log "${registration}"
  regex='(https?)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'
  if [[ ${registration} =~ ${regex} ]]; then
    _log User created on database
  else
    _log User creation failed
    return 1
  fi
  user_uuid=$(echo "${registration}" | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | cut -d/ -f6)
  user_token=$(echo "${registration}" | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | cut -d/ -f7)

  createGPGKey "${email}"

  _log Registering user on passbolt api...
  curl -s "https://${PASSBOLT_FQDN}/setup/complete/${user_uuid}" \
    -H "authority: ${PASSBOLT_FQDN}" \
    -H "accept: application/json" \
    -H "content-type: application/json" \
    --data-raw "{\"authenticationtoken\":{\"token\":\"${user_token}\"},\"gpgkey\":{\"armored_key\":\"$(awk '{printf "%s\\n", $0}' public-${email}.asc)\"}}" \
    --compressed >/dev/null
  _log User "${email}" succesfully registered
  # Fixes an issue on the CI, where user with this key isn't found.
  sleep 10
}

function configurePassbolt {
  local id=${1}
  _log Configuring passbolt cli...
  _log "${PASSBOLT_CLI_BINARY}" configure --serverAddress "https://${PASSBOLT_FQDN}" --userPassword "${PASSPHRASE}" --userPrivateKeyFile "secret-${id}.asc"
  ${PASSBOLT_CLI_BINARY} configure --serverAddress "https://${PASSBOLT_FQDN}" --userPassword "${PASSPHRASE}" --userPrivateKeyFile "secret-${id}.asc"
  _log passbolt cli configured
}

function createPassword {
  local name="${1}"
  local secret="${2}"
  _log "${PASSBOLT_CLI_BINARY}" create resource --name "${name}" --password "${secret}" -j
  ${PASSBOLT_CLI_BINARY} create resource --name "${name}" --password "${secret}" -j
}

function createPasswordInFolder {
  local name="${1}"
  local secret="${2}"
  local folder="${3}"
  _log "${PASSBOLT_CLI_BINARY}" create resource --name "${name}" --password "${secret}" -f "${folder}" -j
  ${PASSBOLT_CLI_BINARY} create resource --name "${name}" --password "${secret}" -f "${folder}" -j
}

function createFolder {
  local name="${1}"
  _log "${PASSBOLT_CLI_BINARY}" create folder --name "${name}" -j
  ${PASSBOLT_CLI_BINARY} create folder --name "${name}" -j
}

function sharePassword {
  local id=${1}
  local user_id=${2}
  local type="${3}"
  _log "${PASSBOLT_CLI_BINARY}" share resource --id "${id}" --user "${user_id}" --type "${type}"
  ${PASSBOLT_CLI_BINARY} share resource --id "${id}" --user "${user_id}" --type "${type}"
}

function getUserIdByUsername {
  local username="${1}"
  _log "${PASSBOLT_CLI_BINARY}" list user --filter "Username == \"${username}\"" -j | jq -r .[0].id
  ${PASSBOLT_CLI_BINARY} list user --filter "Username == \"${username}\"" -j | jq -r .[0].id
}

function getPasswordSecretById {
  local id="${1}"
  _log "${PASSBOLT_CLI_BINARY}" get resource --id "${id}" -j | jq -r .password
  "${PASSBOLT_CLI_BINARY}" get resource --id "${id}" -j | jq -r .password
}
