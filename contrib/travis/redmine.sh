#!/bin/bash

REDMINE_SOURCE_URL="http://www.redmine.org/releases"
REDMINE_NAME="redmine-${REDMINE_VERSION}"
REDMINE_PACKAGE="${REDMINE_NAME}.tar.gz"
REDMINE_URL="${REDMINE_SOURCE_URL}/${REDMINE_PACKAGE}"

version=(${REDMINE_VERSION//./ })
major=${version[0]}
minor=${version[1]}
patch=${version[2]}

GITHUB_SOURCE="${GITHUB_USER}/${GITHUB_PROJECT}"
PLUGIN_PATH=${PLUGIN_PATH:-$GITHUB_SOURCE}
PLUGIN_NAME=${PLUGIN_NAME:-$GITHUB_PROJECT}


function install_redmine() {
  echo ""

  echo "#### GET TARBALL"
  wget "${REDMINE_URL}"
  echo "Done !"
  echo ""

  echo "#### EXTRACT IT"
  tar xf "${REDMINE_PACKAGE}"
  echo "Done !"
  echo ""

  echo "#### MOVE PLUGIN"
  mv "${PLUGIN_PATH}" "${REDMINE_NAME}/plugins"
  rmdir "${PLUGIN_PATH}"
  echo "Done !"
  echo ""

  echo "#### CREATE SYMLINK"
  ln -s "${REDMINE_NAME}" "redmine"
  ln -s "redmine/plugins/redmine_git_hosting/.git" "${REDMINE_NAME}/.git"
  echo "Done !"
  echo ""

  echo "#### INSTALL DATABASE FILE"
  if [ "$DATABASE_ADAPTER" == "mysql" ] ; then
    echo "Type : mysql"
    cp "redmine/plugins/${PLUGIN_NAME}/spec/database_mysql.yml" "redmine/config/database.yml"
  else
    echo "Type : postgres"
    cp "redmine/plugins/${PLUGIN_NAME}/spec/database_postgres.yml" "redmine/config/database.yml"
  fi

  echo "Done !"
  echo ""
}


function install_rspec() {
  echo "#### INSTALL RSPEC FILE"
  mkdir "redmine/spec"
  cp "redmine/plugins/${PLUGIN_NAME}/spec/root_spec_helper.rb" "redmine/spec/spec_helper.rb"
  echo "Done !"
  echo ""

  if [ "$major" == "3" ] ; then
    echo "#### RAILS 4 : INSTALL GEMFILE"
    cp "redmine/plugins/${PLUGIN_NAME}/gemfiles/rails4.gemfile" "redmine/plugins/${PLUGIN_NAME}/Gemfile"
    echo "Done !"
  else
    echo "#### RAILS 3 : INSTALL GEMFILE"
    cp "redmine/plugins/${PLUGIN_NAME}/gemfiles/rails3.gemfile" "redmine/plugins/${PLUGIN_NAME}/Gemfile"
    echo "Done !"

    echo "#### RAILS 3 : UPDATE REDMINE GEMFILE"
    echo "Update shoulda to 3.5.0"
    sed -i 's/gem "shoulda", "~> 3.3.2"/gem "shoulda", "~> 3.5.0"/' "redmine/Gemfile"
    echo "Done !"
    echo ""

    echo "Let update shoulda-matchers to 2.7.0"
    sed -i 's/gem "shoulda-matchers", "1.4.1"/#gem "shoulda-matchers", "1.4.1"/' "redmine/Gemfile"
    echo "Done !"
    echo ""

    echo "Update capybara to 2.2.0"
    sed -i 's/gem "capybara", "~> 2.1.0"/gem "capybara", "~> 2.2.0"/' "redmine/Gemfile"
    echo "Done !"
    echo ""
  fi
}


function finish_install() {
  echo "######################"
  echo "CURRENT DIRECTORY LISTING"
  echo ""

  ls -l "${CURRENT_DIR}"
  echo ""

  echo "######################"
  echo "REDMINE PLUGIN DIRECTORY LISTING"
  echo ""

  ls -l "${REDMINE_NAME}/plugins"
  echo ""
}


function git_clone() {
  plugin_name=$1
  plugin_url=$2

  IFS='#' read url treeish <<< "$plugin_url"

  echo "#### INSTALL ${plugin_name} PLUGIN"

  if [[ "$treeish" == "" ]] ; then
    git clone "${url}" "redmine/plugins/${plugin_name}"
  else
    git clone "${url}" "redmine/plugins/${plugin_name}"
    pushd "redmine/plugins/${plugin_name}" > /dev/null
    git checkout -q "$treeish"
    popd > /dev/null
  fi

  echo "Done !"
  echo ""
}
