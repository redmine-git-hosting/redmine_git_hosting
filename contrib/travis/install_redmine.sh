#!/bin/bash

REDMINE_SIDEKIQ_PLUGIN="https://github.com/ogom/redmine_sidekiq.git"
REDMINE_BOOTSTRAP_PLUGIN="https://github.com/jbox-web/redmine_bootstrap_kit.git"

REDMINE_SOURCE_URL="http://www.redmine.org/releases"
REDMINE_VERSION="2.5.1"

REDMINE_NAME="redmine-${REDMINE_VERSION}"
REDMINE_PACKAGE="${REDMINE_NAME}.tar.gz"
REDMINE_URL="${REDMINE_SOURCE_URL}/${REDMINE_PACKAGE}"

CURRENT_DIR=$(pwd)

echo ""
echo "######################"
echo "REDMINE INSTALLATION SCRIPT"
echo ""
echo "REDMINE_URL : ${REDMINE_URL}"
echo "CURRENT_DIR : ${CURRENT_DIR}"
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
mv "jbox-web/redmine_git_hosting" "${REDMINE_NAME}/plugins"
rmdir "jbox-web"
echo "Done !"
echo ""

echo "#### CREATE SYMLINK"
ln -s "${REDMINE_NAME}" "redmine"
echo "Done !"
echo ""

echo "#### INSTALL DATABASE FILE"
cp "redmine/plugins/redmine_git_hosting/spec/database.yml" "redmine/config/database.yml"
echo "Done !"
echo ""

echo "#### INSTALL RSPEC FILE"
mkdir "redmine/spec"
cp "redmine/plugins/redmine_git_hosting/spec/root_spec_helper.rb" "redmine/spec/spec_helper.rb"
echo "Done !"
echo ""

echo "#### INSTALL ADMIN SSH KEY"
ssh-keygen -N '' -f "redmine/plugins/redmine_git_hosting/ssh_keys/redmine_gitolite_admin_id_rsa"
echo "Done !"
echo ""

echo "#### INSTALL REDMINE SIDEKIQ PLUGIN"
git clone "${REDMINE_SIDEKIQ_PLUGIN}" "redmine/plugins/redmine_sidekiq"
echo "Done !"
echo ""

echo "#### INSTALL REDMINE SIDEKIQ PLUGIN"
git clone "${REDMINE_BOOTSTRAP_PLUGIN}" "redmine/plugins/redmine_bootstrap_kit"
echo "Done !"
echo ""

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
