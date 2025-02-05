#!/bin/bash

set -eo pipefail

DATABASE_ENGINGE=mariadb
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
  if [[ "$RUN_INTEGRATION" == "true" || "$RUN_ALL" == "true" ]]; then
    source tests/integration/fixtures/install_dependencies.sh
    installDependencies
    bash tests/integration/fixtures/create-cluster-with-passbolt.sh "$database"
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
  echo "-d|--database [option]    Database to run integration tests to [mariadb|postgresql]."
  echo "-no-clean                 Skip cleaning step."
  echo
  exit 0
}

function run_all {
  run_linter
  run_unit_tests
  run_integration_tests "$DATABASE_ENGINGE"
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
    DATABASE_ENGINGE=$1
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
