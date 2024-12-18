#!/bin/bash

function testCreateAndRemovePassword {
  local value="to-be-removed"
  local description="It should create and remove a password"
  local test_id=
  test_id="$(date +'%s')"
  local username="email${test_id}@domain.tld"
  _log Running "${test_id}" test
  registerPassboltUser "${FIRSTNAME}" "${LASTNAME}" "${username}" "${test_id}"
  configurePassbolt "${username}"
  id=$(createPassword "${test_id}" "${value}" "${test_id}")
  "${PASSBOLT_CLI_BINARY}" delete resource --id "$(echo "${id}" | jq -r .id)"
  if [[ $? -ne 0 ]]; then
    >&2 echo "Failed to delete the password!"
    return 1
  fi
  echo "${description}"
  _log Test "${test_id}" ran succesfully
}
