#!/bin/bash

function testCreateShareAndDecryptPassword {
  local value="password-example"
  local test_id=
  test_id="$(date +'%s')"
  local source_username="source-${test_id}@domain.tld"
  local destination_username="destination-${test_id}@domain.tld"
  _log Running "${test_id}" test
  registerPassboltUser "${FIRSTNAME}" "${LASTNAME}" "${source_username}"
  registerPassboltUser "${FIRSTNAME}" "${LASTNAME}" "${destination_username}"
  local destination_user_id=
  destination_user_id=$(getUserIdByUsername "${destination_username}")
  configurePassbolt "${source_username}"
  local id=
  id=$(createPassword "${test_id}" "${value}" "${test_id}")
  sharePassword "$(echo "${id}" | jq -r .id)" "${destination_user_id}" "15"
  configurePassbolt "${destination_username}"
  local result=
  result=$(getPasswordSecretById "$(echo "${id}" | jq -r .id)")
  if [[ "${value}" != "${result}" ]]; then
    >&2 echo "Expected \"${value}\", got \"${result}\""
    return 1
  fi
  _log Test "${test_id}" ran succesfully

}
