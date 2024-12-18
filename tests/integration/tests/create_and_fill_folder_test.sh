#!/bin/bash

function createAndFillFolder {
  local name="${1}"
  local test_id="${2}"
  local passwords_count="${3}"

  _log Creating "${name}" folder...
  folder="$(createFolder "${test_id}")"
  _log "${name}" folder created
  folder_id="$(echo "${folder}" | jq -r .id)"
  for index in $(seq 1 "${passwords_count}"); do
    createPasswordInFolder "password${index}" "secret${index}" "${folder_id}"
  done
}

function testCreateAndFillFolder {
  local name="test-folder"
  local test_id=""
  test_id="$(date +'%s')"
  local username="email${test_id}@domain.tld"
  local passwords_count="3"
  _log Running "${test_id}" test
  registerPassboltUser "${FIRSTNAME}" "${LASTNAME}" "${username}" "${test_id}"
  configurePassbolt "${username}"
  createAndFillFolder "${test_id}" "${test_id}" "${passwords_count}"
  _log "${PASSBOLT_CLI_BINARY}" list resource --filter "FolderParentID == \"${folder_id}\"" -j
  resources=$("${PASSBOLT_CLI_BINARY}" list resource --filter "FolderParentID == \"${folder_id}\"" -j)
  _log "Resources in ${folder_id} folder: \n${resources}"
  resources_count="$(echo "${resources}" | jq -r 'length')"
  if [ "${resources_count}" != 3 ]; then
    >&2 echo "Expected 3 resources in ${test_id} folder, got ${resources_count}"
    return 1
  fi
}
