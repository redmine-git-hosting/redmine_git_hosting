#!/bin/bash

REDMINE_INSTALLER_DIR=$(dirname "$(readlink -f "$0")")
source "$REDMINE_INSTALLER_DIR/common.sh"
source "$REDMINE_INSTALLER_DIR/plugin.sh"
source "$REDMINE_INSTALLER_DIR/redmine.sh"

CURRENT_DIR=$(pwd)

echo ""
echo "######################"
echo "REDMINE INSTALLATION SCRIPT"
echo ""
echo "REDMINE_VERSION : ${REDMINE_VERSION}"
echo "REDMINE_URL     : ${REDMINE_URL}"
echo "CURRENT_DIR     : ${CURRENT_DIR}"
echo "GITHUB_SOURCE   : ${GITHUB_SOURCE}"
echo "PLUGIN_PATH     : ${PLUGIN_PATH}"
echo ""

install_plugin_packages
install_redmine
install_plugin
install_rspec
install_plugin_dependencies
finish_install
