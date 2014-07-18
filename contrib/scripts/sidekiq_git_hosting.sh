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

# WORKER_NAME is used to identify the worker among the processus list
# Example : sidekiq 3.2.1 redmine_git_hosting [0 of 1 busy]
WORKER_NAME="redmine_git_hosting"

# The Rails environment, default : production
RAILS_ENV=${RAILS_ENV:-production}

# The absolute path to Redmine
REDMINE_PATH=${REDMINE_PATH:-$HOME/redmine}

# The start detection timeout
TIMEOUT=${TIMEOUT:-15}

DESC="Sidekiq worker '$WORKER_NAME'"

LOG_DIR="$REDMINE_PATH/log"
PID_DIR="$REDMINE_PATH/tmp/pids"

LOG_FILE="$LOG_DIR/worker_${WORKER_NAME}.log"
PID_FILE="$PID_DIR/worker_${WORKER_NAME}.pid"

# Do not change these values !
# See here for more details :
# https://github.com/jbox-web/redmine_git_hosting/wiki/Configuration-notes#sidekiq--concurrency
CONCURRENCY=1
QUEUE="redmine_git_hosting,1"

if [ "$RAILS_ENV" = "production" ] ; then
  DAEMON_OPTS="--daemon --logfile $LOG_FILE --pidfile $PID_FILE"
else
  DAEMON_OPTS=
fi

if [ ! -d $PID_DIR ] ; then
  mkdir $PID_DIR
fi


RETVAL=0


################################
success() {
  echo -e "\t\t[ \e[32mOK\e[0m ]"
}


failure() {
  echo -e "\t\t[ \e[31mFailure\e[0m ]"
}


start () {
  pid=$(get_pid)
  if [ $pid -gt 1 ] ; then
    echo "$DESC is already running (pid $pid)"
    RETVAL=1
    return $RETVAL
  fi

  echo -n "Starting $DESC ..."

  sidekiq $DAEMON_OPTS --verbose --concurrency $CONCURRENCY \
          --environment $RAILS_ENV --require $REDMINE_PATH \
          --queue $QUEUE --tag $WORKER_NAME

  if [ ! -z "$DAEMON_OPTS" ] ; then
    for ((i=1; i<=TIMEOUT; i++)) ; do
      pid=$(get_pid)
      if [ $pid -gt 1 ] ; then
        break
      fi
      echo -n '.' && sleep 1
    done
    echo -n " "

    pid=$(get_pid)
    if [ $pid -gt 1 ] ; then
      success
      RETVAL=0
    else
      failure
      RETVAL=1
    fi
  fi
}


stop () {
  echo -n "Shutting down $DESC ..."
  kill $(cat $PID_FILE 2>/dev/null) >/dev/null 2>&1
  RETVAL=$?
  [ $RETVAL -eq 0 ] && success || failure
  rm -f $PID_FILE >/dev/null 2>&1
}


status () {
  # show status
  pid=$(get_pid)
  if [ $pid -gt 1 ] ; then
    echo "$DESC is running (pid $pid)"
  else
    echo "$DESC is stopped"
  fi
  RETVAL=0
}


get_pid () {
  # get status
  pid=$(ps axo pid,command | grep sidekiq | grep $WORKER_NAME | awk '{print $1}')
  if [ -z $pid ] ; then
    rc=1
  else
    rc=$pid
  fi
  echo $rc
}

################################

case "$1" in
  start)
    start
  ;;
  stop)
    stop
  ;;
  restart)
    stop
    sleep 1
    start
  ;;
  status)
    status
  ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
  ;;
esac

exit $RETVAL
