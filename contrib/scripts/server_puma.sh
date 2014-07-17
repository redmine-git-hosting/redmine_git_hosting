#!/bin/bash

# You should place this script in user's home bin dir like :
# /home/redmine/bin/server_puma.sh
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
# redmine$ server_puma.sh start
# redmine$ server_puma.sh stop
# redmine$ server_puma.sh restart
#

SERVER_NAME="redmine"

RAILS_ENV="production"

REDMINE_PATH="$HOME/redmine"
BIND_URI="unix://$REDMINE_PATH/tmp/sockets/redmine.sock"
PID_FILE="$REDMINE_PATH/tmp/pids/puma.pid"
CONFIG_FILE="$HOME/etc/puma.rb"

function start () {
  echo "Start Puma Server..."
  puma --daemon --preload --bind $BIND_URI \
       --environment $RAILS_ENV --dir $REDMINE_PATH \
       --pidfile $PID_FILE --tag $SERVER_NAME \
       --config $CONFIG_FILE
  echo "Done"
}

function stop () {
  echo "Stop Puma Server..."
  kill $(cat $PID_FILE) 2>/dev/null
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
    start
  ;;
  *)
    echo "Usage : server_puma.sh {start|stop|restart}"
  ;;
esac
