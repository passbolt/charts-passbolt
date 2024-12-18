#!/bin/bash

function testCreateAndDecryptPassword {
  local value="password-example"
  local test_id=
  test_id="$(date +'%s')"
  local username="email${test_id}@domain.tld"
  _log Running "${test_id}" test
  registerPassboltUser "${FIRSTNAME}" "${LASTNAME}" "${username}" "${test_id}"
  configurePassbolt "${username}"
  password=$(createPassword "${test_id}" "${value}" "${test_id}")
  result=$("${PASSBOLT_CLI_BINARY}" get resource --id "$(echo "${password}" | jq -r .id)" -j | jq -r .password)
  if [[ "${value}" != "${result}" ]]; then
    >&2 echo "Expected \"${value}\", got \"${result}\""
    return 1
  fi
  _log Test "${test_id}" ran succesfully
}
