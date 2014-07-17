#!/bin/bash

# You should place this script in user's home bin dir like :
# /home/redmine/bin/sidekiq_git_hosting.sh
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
# redmine$ sidekiq_git_hosting.sh start
# redmine$ sidekiq_git_hosting.sh stop
# redmine$ sidekiq_git_hosting.sh restart

WORKER_NAME="redmine_git_hosting"

RAILS_ENV="production"

REDMINE_PATH="$HOME/redmine"
LOG_FILE="$REDMINE_PATH/log/worker_${WORKER_NAME}.log"
PID_FILE="$REDMINE_PATH/tmp/pids/worker_${WORKER_NAME}.pid"

# Do not change these values !
# See here for more details :
# https://github.com/jbox-web/redmine_git_hosting/wiki/Configuration-notes#sidekiq--concurrency
CONCURRENCY=1
QUEUE="git_hosting,1"

function start () {
  echo "Start Sidekiq..."
  sidekiq --daemon --verbose --concurrency $CONCURRENCY \
          --environment $RAILS_ENV --require $REDMINE_PATH \
          --logfile $LOG_FILE --pidfile $PID_FILE \
          --queue $QUEUE --tag $WORKER_NAME
  echo "Done"
}

function stop () {
  echo "Stop Sidekiq..."
  if [ -f $PID_FILE ] ; then
    kill $(cat $PID_FILE) 2>/dev/null
    rm -f $PID_FILE
  fi
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
    echo "Usage : sidekiq_git_hosting.sh {start|stop|restart}"
  ;;
esac
