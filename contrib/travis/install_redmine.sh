#!/bin/bash

REDMINE_SOURCE_URL="http://www.redmine.org/releases"
REDMINE_VERSION="2.5.1"

REDMINE_NAME="redmine-${REDMINE_VERSION}"
REDMINE_PACKAGE="${REDMINE_NAME}.tar.gz"
REDMINE_URL="${REDMINE_SOURCE_URL}/${REDMINE_PACKAGE}"

CURRENT_DIR=$(pwd)
INSTALL_DIR="${CURRENT_DIR}/REDMINE_INSTALL"

echo ""
echo "######################"
echo ""
echo "REDMINE_URL : ${REDMINE_URL}"
echo "INSTALL_DIR : ${INSTALL_DIR}"
echo ""
echo "######################"
echo ""

if [ -d "${INSTALL_DIR}" ] ; then
  rm -rf "${INSTALL_DIR}"
fi

mkdir "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

wget "${REDMINE_URL}"
tar xf "${REDMINE_PACKAGE}"

ls -hal "${REDMINE_NAME}"
