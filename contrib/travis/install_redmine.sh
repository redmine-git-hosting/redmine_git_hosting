#!/bin/bash

REDMINE_SOURCE_URL="http://www.redmine.org/releases"

REDMINE_NAME="redmine-${REDMINE_VERSION}"
REDMINE_PACKAGE="${REDMINE_NAME}.tar.gz"
REDMINE_URL="${REDMINE_SOURCE_URL}/${REDMINE_PACKAGE}"

PLUGIN_SOURCE="jbox-web"
PLUGIN_NAME="redmine_git_hosting"

REDMINE_SIDEKIQ_PLUGIN="https://github.com/ogom/redmine_sidekiq.git"
REDMINE_BOOTSTRAP_PLUGIN="https://github.com/jbox-web/redmine_bootstrap_kit.git"

CURRENT_DIR=$(pwd)

echo ""
echo "######################"
echo "REDMINE INSTALLATION SCRIPT"
echo ""
echo "REDMINE_VERSION : ${REDMINE_VERSION}"
echo "REDMINE_URL     : ${REDMINE_URL}"
echo "CURRENT_DIR     : ${CURRENT_DIR}"
echo "PLUGIN_ORIGIN   : ${PLUGIN_SOURCE}/${PLUGIN_NAME}"
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
mv "${PLUGIN_SOURCE}/${PLUGIN_NAME}" "${REDMINE_NAME}/plugins"
rmdir "${PLUGIN_SOURCE}"
echo "Done !"
echo ""

echo "#### CREATE SYMLINK"
ln -s "${REDMINE_NAME}" "redmine"
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

echo "#### INSTALL RSPEC FILE"
mkdir "redmine/spec"
cp "redmine/plugins/${PLUGIN_NAME}/spec/root_spec_helper.rb" "redmine/spec/spec_helper.rb"
echo "Done !"
echo ""

echo "#### INSTALL ADMIN SSH KEY"
ssh-keygen -N '' -f "redmine/plugins/${PLUGIN_NAME}/ssh_keys/redmine_gitolite_admin_id_rsa"
echo "Done !"
echo ""

if [ "$TRAVIS_RUBY_VERSION" != "1.9.3" ] ; then
  echo "#### INSTALL REDMINE SIDEKIQ PLUGIN"
  git clone "${REDMINE_SIDEKIQ_PLUGIN}" "redmine/plugins/redmine_sidekiq"
  echo "Done !"
  echo ""
fi

echo "#### INSTALL REDMINE BOOTSTRAP PLUGIN"
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

echo "######################"
echo "INSTALL GITOLITE V3"
echo ""

sudo useradd --create-home git
sudo -n -u git -i git clone https://github.com/sitaramc/gitolite.git
sudo -n -u git -i mkdir bin
sudo -n -u git -i gitolite/install -to /home/git/bin
sudo cp "redmine/plugins/${PLUGIN_NAME}/ssh_keys/redmine_gitolite_admin_id_rsa.pub" /home/git/
sudo chown git.git /home/git/redmine_gitolite_admin_id_rsa.pub
sudo -n -u git -i gitolite setup -pk redmine_gitolite_admin_id_rsa.pub
