#!/bin/bash

function log_header() {
  echo "######################"
  echo $1
  echo ""
}


function log_title() {
  echo "#### $1"
}


function log_ok() {
  echo "Done !"
  echo ""
}


function git_clone() {
  plugin_name=$1
  plugin_url=$2

  IFS='#' read url treeish <<< "$plugin_url"

  log_title "INSTALL ${plugin_name} PLUGIN"

  if [[ "$treeish" == "" ]] ; then
    git clone "${url}" "redmine/plugins/${plugin_name}"
  else
    git clone "${url}" "redmine/plugins/${plugin_name}"
    pushd "redmine/plugins/${plugin_name}" > /dev/null
    git checkout -q "$treeish"
    popd > /dev/null
  fi

  log_ok
}
