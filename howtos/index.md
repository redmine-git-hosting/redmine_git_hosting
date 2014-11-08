---
layout: default
title: How Tos
group: navigation
weight: 4
---

### Step by Step installation
***

{% include guide/step1.md %}
{% include guide/step2.md %}
{% include guide/step3.md %}
{% include guide/step4.md %}
{% include guide/step5.md %}
{% include guide/step6.md %}
{% include guide/step7.md %}
{% include guide/step8.md %}

***

### Sidekiq mode

There are additional steps to pass if you want to use the plugin in Sidekiq mode :

#### **(step 1)** Install Redis Server

    ## I use Redis Server from packages.dotdeb.org on Debian Wheezy
    ## so you can add this to /etc/apt/sources.list :
    ## deb http://packages.dotdeb.org/  wheezy all
    ## or for Squeeze :
    ## deb http://packages.dotdeb.org/  squeeze all

    ## then
    root$ apt-get update
    root$ apt-get install redis-server


***

#### **(step 2)** Install the Sidekiq plugin

<div class="alert alert-warning" role="alert">This plugin <b>does not support Ruby 1.9 !</b></div>

<div class="alert alert-warning" role="alert">Before install the plugin, stop Redmine!</div>

    root$ su - redmine
    redmine$ cd REDMINE_ROOT/plugins
    redmine$ git clone https://github.com/ogom/redmine_sidekiq.git
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without development test

***

#### **(step 3)** Switch mode

Go in *Administration -> Redmine Git Hosting -> Sidekiq tab* then enable Sidekiq mode.

From this point, all actions on projects or repositories are queued in the Redis database.

To execute them you must now run the Sidekiq worker.

***

#### **(step 4)** Run Sidekiq worker

A startup script [```contrib/scripts/sidekiq_git_hosting.sh```](https://github.com/jbox-web/redmine_git_hosting/blob/devel/contrib/scripts/sidekiq_git_hosting.sh) is provided by the plugin.

You should place this script in Redmine user's home bin dir like : ```/home/redmine/bin/sidekiq_git_hosting.sh```.

Normally the Redmine user's bin directory should be in the PATH.

If not, add this in /home/redmine/.profile :

    # Set PATH so it includes user's private bin if it exists
    if [ -d "$HOME/bin" ] ; then
      PATH="$HOME/bin:$PATH"
    fi

***

### Step by Step upgrade

<div class="alert alert-warning" role="alert">Before update the plugin, stop Redmine!</div>

    root$ su - redmine

    redmine$ cd REDMINE_ROOT/plugins/redmine_git_hosting
    redmine$ git fetch
    redmine$ git checkout {{ site.data.project.release.version }}
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without development test
    redmine$ RAILS_ENV=production NAME=redmine_git_hosting rake redmine:plugins:migrate

***

### Step by Step removal

I'm sorry you didn't find any satisfaction in this plugin.

If you want to remove it just follow the steps :

<div class="alert alert-warning" role="alert">Before update the plugin, stop Redmine!</div>

    root$ su - redmine

    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production NAME=redmine_git_hosting VERSION=0 rake redmine:plugins:migrate
    redmine$ rm -rf REDMINE_ROOT/plugins/redmine_git_hosting

***

### Step by Step migration

If you're upgrading from 0.6 version (or older) you should follow these steps :

<div class="alert alert-warning" role="alert">Before update the plugin, stop Redmine!</div>

    root$ su - redmine

    redmine$ cd REDMINE_ROOT/plugins
    redmine$ rm -rf redmine_git_hosting
    redmine$ git clone https://github.com/ogom/redmine_sidekiq.git
    redmine$ git clone https://github.com/jbox-web/redmine_bootstrap_kit.git
    redmine$ git clone https://github.com/jbox-web/redmine_git_hosting.git
    redmine$ cd redmine_git_hosting/
    redmine$ git checkout {{ site.data.project.release.version }}
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without development test
    redmine$ RAILS_ENV=production NAME=redmine_git_hosting rake redmine:plugins:migrate

Now you must start Redmine to check everything is working.

Go to *Administration -> Redmine Git Hosting -> Config Checks*, everything should be green.

If not, check your configuration.

Then you must update SSH keys by running the following command :

    redmine$ RAILS_ENV=production rake redmine_git_hosting:rename_ssh_keys


<div id="toc">
</div>
