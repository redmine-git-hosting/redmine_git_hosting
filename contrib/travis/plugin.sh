#!/bin/bash

GITHUB_USER=${GITHUB_USER:-jbox-web}
GITHUB_PROJECT=${GITHUB_PROJECT:-redmine_git_hosting}

function install_packages() {
  sudo apt-get update -qq
  sudo apt-get install -qq libicu-dev libssh2-1 libssh2-1-dev cmake
}


function install_plugin() {
  git_clone 'redmine_bootstrap_kit' 'https://github.com/jbox-web/redmine_bootstrap_kit.git'
  git_clone 'redmine_sidekiq'       'https://github.com/ogom/redmine_sidekiq.git'
  install_ssh_key
  install_gitolite
}


function install_ssh_key() {
  echo "#### INSTALL ADMIN SSH KEY"
  ssh-keygen -N '' -f "redmine/plugins/${PLUGIN_NAME}/ssh_keys/redmine_gitolite_admin_id_rsa"
  echo "Done !"
  echo ""
}


function install_gitolite() {
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
}
