#!/bin/bash

set -eo pipefail

DATABASE_ENGINE=mariadb
PROTOCOL=https
GPG_KEY_GENERATION=auto
RUN_UNIT=false
RUN_LINT=false
RUN_INTEGRATION=false
RUN_ALL=true
CLEAN_INTEGRATION_ASSETS=true

function run_linter {
  if [[ "$RUN_LINT" == "true" || "$RUN_ALL" == "true" ]]; then
    helm lint .
  fi
}

function run_unit_tests {
  if [[ "$RUN_UNIT" == "true" || "$RUN_ALL" == "true" ]]; then
    helm unittest --color .
  fi
}

function run_integration_tests {
  local database="$1"
  local protocol="$2"
  local gpg_key_generation="$3"
  if [[ "$RUN_INTEGRATION" == "true" || "$RUN_ALL" == "true" ]]; then
    source tests/integration/fixtures/install_dependencies.sh
    installDependencies
    bash tests/integration/fixtures/create-cluster-with-passbolt.sh -d "$database" -p "$protocol" -g "$gpg_key_generation"
    "$HELM_BINARY" test --logs passbolt -n default
  fi
}

function clean_integration_assets {
  if [[ "$RUN_INTEGRATION" == "true" ]] || [[ "$RUN_ALL" == "true" ]] && [[ "$CLEAN_INTEGRATION_ASSETS" == "true" ]]; then
    echo Cleaning integration testing assets...
    rm -f helm kubectl kind mkcerts passbolt
  fi
}

function showHelp {
  echo "Run the available tests for passbolt helm charts"
  echo
  echo "Syntax: $0 [options]"
  echo "$0 with no arguments will run all of the available tests."
  echo
  echo "options:"
  echo "-h|--help                 Show this message."
  echo "-l|--lint                 Run helm lint."
  echo "-u|--unit                 Run helm unittest tests."
  echo "-i|--integration          Run integration tests."
  echo "-d|--database [optional]  Database to run integration tests to [mariadb|postgresql]."
  echo "-p|--protocol [optional]  Http protocol scheme to run integration tests to [http|https]."
  echo "-g|--gpg [optional]  	  Automagically create GPG key using init job or manually through secrets. [auto|provided|existing_secret]"
  echo "-no-clean                 Skip cleaning step."
  echo
  exit 0
}

function run_all {
  run_linter
  run_unit_tests
  run_integration_tests "$DATABASE_ENGINE" "$PROTOCOL" "$GPG_KEY_GENERATION"
  clean_integration_assets
}

while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    showHelp
    ;;
  -l | --lint)
    RUN_ALL=false
    RUN_LINT=true
    shift
    ;;
  -u | --unit)
    RUN_ALL=false
    RUN_UNIT=true
    shift
    ;;
  -i | --integration)
    RUN_ALL=false
    RUN_INTEGRATION=true
    shift
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
  --no-clean)
    CLEAN_INTEGRATION_ASSETS=false
    shift
    ;;
  *)
    echo "Unknown argurment $1"
    shift
    ;;
  esac
done

run_all
