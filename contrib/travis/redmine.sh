#!/bin/bash

REDMINE_PACKAGE_URL="http://www.redmine.org/releases"
REDMINE_SVN_URL="https://svn.redmine.org/redmine/branches"

REDMINE_NAME="redmine-${REDMINE_VERSION}"
REDMINE_PACKAGE="${REDMINE_NAME}.tar.gz"
REDMINE_URL="${REDMINE_PACKAGE_URL}/${REDMINE_PACKAGE}"

USE_SVN=${USE_SVN:-false}

version=(${REDMINE_VERSION//./ })
major=${version[0]}
minor=${version[1]}
patch=${version[2]}

GITHUB_SOURCE="${GITHUB_USER}/${GITHUB_PROJECT}"
PLUGIN_PATH=${PLUGIN_PATH:-$GITHUB_SOURCE}
PLUGIN_NAME=${PLUGIN_NAME:-$GITHUB_PROJECT}


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


function install_redmine() {
  if [ $USE_SVN == 'true' ] ; then
    install_redmine_from_svn
  else
    install_redmine_from_package
  fi
}


function install_plugin() {
  log_title "MOVE PLUGIN"
  # Move GITHUB_USER/GITHUB_PROJECT to redmine/plugins dir
  mv "${PLUGIN_PATH}" "${REDMINE_NAME}/plugins"
  # Remove parent dir (GITHUB_USER)
  rmdir $(dirname ${PLUGIN_PATH})
  log_ok

  log_title "CREATE SYMLINK"
  ln -s "${REDMINE_NAME}" "redmine"
  ln -s "redmine/plugins/redmine_git_hosting/.git" "${REDMINE_NAME}/.git"
  log_ok

  log_title "INSTALL DATABASE FILE"
  if [ "$DATABASE_ADAPTER" == "mysql" ] ; then
    echo "Type : mysql"
    cp "redmine/plugins/${PLUGIN_NAME}/spec/database_mysql.yml" "redmine/config/database.yml"
  else
    echo "Type : postgres"
    cp "redmine/plugins/${PLUGIN_NAME}/spec/database_postgres.yml" "redmine/config/database.yml"
  fi

  log_ok
}


function install_rspec() {
  log_title "INSTALL RSPEC FILE"
  mkdir "redmine/spec"
  cp "redmine/plugins/${PLUGIN_NAME}/spec/root_spec_helper.rb" "redmine/spec/spec_helper.rb"
  log_ok

  if [ "$major" == "3" ] ; then
    if [ -f "redmine/plugins/${PLUGIN_NAME}/gemfiles/rails4.gemfile" ] ; then
      log_title "RAILS 4 : INSTALL GEMFILE"
      cp "redmine/plugins/${PLUGIN_NAME}/gemfiles/rails4.gemfile" "redmine/plugins/${PLUGIN_NAME}/Gemfile"
      log_ok
    fi
  else

    if [ -f "redmine/plugins/${PLUGIN_NAME}/gemfiles/rails3.gemfile" ] ; then
      log_title "RAILS 3 : INSTALL GEMFILE"
      cp "redmine/plugins/${PLUGIN_NAME}/gemfiles/rails3.gemfile" "redmine/plugins/${PLUGIN_NAME}/Gemfile"
      log_ok
    fi

    log_title "RAILS 3 : UPDATE REDMINE GEMFILE"

    echo "Update shoulda to 3.5.0"
    sed -i 's/gem "shoulda", "~> 3.3.2"/gem "shoulda", "~> 3.5.0"/' "redmine/Gemfile"
    log_ok

    echo "Let update shoulda-matchers to 2.7.0"
    sed -i 's/gem "shoulda-matchers", "1.4.1"/#gem "shoulda-matchers", "1.4.1"/' "redmine/Gemfile"
    log_ok

    echo "Update capybara to 2.2.0"
    sed -i 's/gem "capybara", "~> 2.1.0"/gem "capybara", "~> 2.2.0"/' "redmine/Gemfile"
    log_ok
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
