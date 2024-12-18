#!/bin/bash

# Prints debug logs if TESTS_DEBUG is true
function _echo {
  if [ "${TESTS_DEBUG}" == true ]; then
    printf '[DEBUG]: %s\n' "${DEBUG_MESSAGES[@]}"
  fi
  DEBUG_MESSAGES=()
}

# Appends debug logs to a variable
function _log {
  local message="$*"
  DEBUG_MESSAGES+=("${message[*]}")
}
