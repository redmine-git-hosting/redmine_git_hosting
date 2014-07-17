#!/bin/bash

# You should place this script in user's home bin dir like :
# /home/redmine/bin/service_sidekiq.sh
#
# Normally the user's bin directory should be in the PATH.
# If not, add this in /home/redmine/.profile :
#
# ------------------>8
# #set PATH so it includes user's private bin if it exists
# if [ -d "$HOME/bin" ] ; then
#   PATH="$HOME/bin:$PATH"
# fi
# ------------------>8
#
#
# This script *must* be run by the Redmine user so
# switch user *before* running the script :
# root$ su - redmine
#
# Then :
# redmine$ service_sidekiq start
# redmine$ service_sidekiq stop
# redmine$ service_sidekiq restart
#

REDMINE_PATH="$HOME/redmine"
CONFIG_FILE="$HOME/redmine/plugins/redmine_git_hosting/config/sidekiq-worker.yml"
PID_FILE="$HOME/redmine/tmp/pids/worker_redmine_git_hosting.pid"

function start () {
  echo "Start Sidekiq..."
  export RAILS_ENV=production
  cd $REDMINE_PATH && sidekiq -C $CONFIG_FILE
  echo "Done"
}

function stop () {
  echo "Stop Sidekiq..."
  kill $(cat $PID_FILE)
  echo "Done"
}

case "$1" in
  start)
    start
  ;;
  stop)
    stop
  ;;
  restart)
    stop
    sleep1
    start
  ;;
  *)
    echo "Usage : service_sidekiq.sh {start|stop|restart}"
  ;;
esac
