#!/bin/bash


function start () {
  echo "Start Sidekiq..."
  cd "$HOME/redmine/" && sidekiq -C plugins/redmine_git_hosting/sidekiq.yml
  echo "Done"
}

function stop () {
  echo "Stop Sidekiq..."
  kill $(cat $HOME/redmine/tmp/pids/sidekiq.pid)
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
    echo "Usage : service_sidekiq.sh {start|stop|restart}"
  ;;
esac
