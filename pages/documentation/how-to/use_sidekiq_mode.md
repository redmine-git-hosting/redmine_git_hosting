---
title: Use Sidekiq mode
permalink: /how-to/use-sidekiq-mode/
---

There are additional steps to pass if you want to use the plugin in Sidekiq mode :

#### **(step 1)** Install Redis Server
***

    root# apt-get update
    root# apt-get install redis-server


#### **(step 2)** Install the Sidekiq plugin
***

{{ site.data.callouts.alertwarning }}
  Before installing the plugin, stop Redmine!
{{ site.data.callouts.end }}

    root# su - redmine
    redmine$ cd REDMINE_ROOT/plugins
    redmine$ git clone https://github.com/ogom/redmine_sidekiq.git
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install


#### **(step 3)** Switch mode
***

Go in *Administration -> Redmine Git Hosting -> Sidekiq tab* then enable Sidekiq mode.

From this point, all actions on projects or repositories are queued in the Redis database.

To execute them you must now run the Sidekiq worker.


#### **(step 4)** Run Sidekiq worker
***

A startup script [```contrib/scripts/sidekiq_git_hosting.sh```](https://github.com/jbox-web/redmine_git_hosting/blob/devel/contrib/scripts/sidekiq_git_hosting.sh) is provided by the plugin.

You should place this script in Redmine user's home bin dir like : ```/home/redmine/bin/sidekiq_git_hosting.sh```.

Normally the Redmine user's bin directory should be in the ```PATH```.

If not, add this in ```/home/redmine/.profile``` :

    # Set PATH so it includes user's private bin if it exists
    if [ -d "$HOME/bin" ] ; then
      PATH="$HOME/bin:$PATH"
    fi


#### **(Notes)** Sidekiq :: Concurrency
***

When running in Sidekiq mode, do **not** modify ```sidekiq.yml```, particularly the ```concurrency``` parameter.

Tasks are async but cannot be parallels as we need to write in a file.

Hence the sidekiq worker is a one-queue worker and tasks are stacked **in order** in the queue.

Modifying the ```concurrency``` parameter would break the order of tasks and could lead to an inconsistent state of the Gitolite configuration file.
