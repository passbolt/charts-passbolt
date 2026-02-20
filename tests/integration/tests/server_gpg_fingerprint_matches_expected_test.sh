#!/bin/bash

function testServerGpgFingerprintMatchesExpected {
  local test_id="$(date +'%s')"
  if [[ -z "${EXPECTED_GPG_FINGERPRINT}" ]]; then
    _log "Test ${test_id} skipped as expected GPG fingerprint is set to empty string."
    return
  fi
  _log Running "${test_id}" test
  result=$(curl -s "${PROTOCOL}://${PASSBOLT_FQDN}/auth/verify.json" | jq .body.fingerprint --raw-output)
  if [[ "${EXPECTED_GPG_FINGERPRINT}" != "${result}" ]]; then
    >&2 echo "Expected \"${EXPECTED_GPG_FINGERPRINT}\", got \"${result}\""
    return 1
  fi
  _log Test "${test_id}" ran succesfully
}
