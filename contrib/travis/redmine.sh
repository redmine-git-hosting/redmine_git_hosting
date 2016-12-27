#!/bin/bash

REDMINE_PACKAGE_URL="http://www.redmine.org/releases"
REDMINE_SVN_URL="https://svn.redmine.org/redmine/branches"
REDMINE_GIT_URL="https://github.com/redmine/redmine.git"

REDMINE_NAME="redmine-${REDMINE_VERSION}"
REDMINE_PACKAGE="${REDMINE_NAME}.tar.gz"
REDMINE_URL="${REDMINE_PACKAGE_URL}/${REDMINE_PACKAGE}"

USE_SVN=${USE_SVN:-false}

version=(${REDMINE_VERSION//./ })
major=${version[0]}
minor=${version[1]}
patch=${version[2]}


function install_redmine() {
  install_redmine_libs

  if [ $USE_SVN == 'true' ] ; then
    # install_redmine_from_svn
    install_redmine_from_git
  else
    install_redmine_from_package
  fi
}

function finish_install() {
  log_header "CURRENT DIRECTORY LISTING"
  ls -l "${CURRENT_DIR}"
  echo ""

  log_header "REDMINE PLUGIN DIRECTORY LISTING"
  ls -l "${REDMINE_NAME}/plugins"
  echo ""
}

## PRIVATE


function install_redmine_libs() {
  log_title "INSTALL REDMINE LIBS"
  sudo apt-get install -qq subversion
  log_ok
}


function install_redmine_from_package() {
  log_title "GET TARBALL"
  wget "${REDMINE_URL}"
  log_ok

  log_title "EXTRACT IT"
  tar xf "${REDMINE_PACKAGE}"
  log_ok
}


function install_redmine_from_svn() {
  log_title "GET SOURCES FROM SVN"
  svn co --non-interactive --trust-server-cert "${REDMINE_SVN_URL}/${REDMINE_VERSION}" "${REDMINE_NAME}"
  log_ok
}


function install_redmine_from_git() {
  log_title "GET SOURCES FROM GIT"
  git clone "${REDMINE_GIT_URL}" "${REDMINE_NAME}"
  pushd "${REDMINE_NAME}"
  git checkout "${REDMINE_VERSION}"
  popd
  log_ok
}
