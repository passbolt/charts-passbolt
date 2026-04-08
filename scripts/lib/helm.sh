#!/bin/bash

function check_helm_plugin() {
  local plugin_name=$1
  local plugin_installed
  plugin_installed=$(helm plugin list | grep "$plugin_name" | awk '{print $1}')
  if [[ "$plugin_installed" == "" ]]; then
    echo "Helm plugin $plugin_name is not installed."
    return 1
  fi
}

function install_helm_plugin() {
  local plugin_name=$1
  local plugin_url=$2
  echo "Installing helm plugin $plugin_name"
  # TODO: remove this version pin when helm-gcs publishes correctly 0.4.3
  helm plugin install "$plugin_url" --version 0.4.1 > /dev/null
}

function ensure_helm_plugin() {
  local plugin_name=$1
  local plugin_url=$2
  if ! check_helm_plugin "$plugin_name"; then
    install_helm_plugin "$plugin_name" "$plugin_url"
  fi
}
