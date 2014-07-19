---
layout: default
title: Step By Step installation
---

<div id="toc">
</div>


### Basic install
***

{% include guide/step1.md %}
{% include guide/step2.md %}
{% include guide/step3.md %}
{% include guide/step4.md %}
{% include guide/step5.md %}
{% include guide/step6.md %}
{% include guide/step7.md %}
{% include guide/step8.md %}
{% include guide/step9.md %}

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

#### **(step 2)** Switch mode

Go in *Administration -> Redmine Git Hosting -> Sidekiq tab* then enable Sidekiq mode.

From this point, all actions on projects or repositories are queued in the Redis database.

To execute them you must now run the Sidekiq worker.

***

#### **(step 3)** Run Sidekiq worker

A startup script [```contrib/scripts/sidekiq_git_hosting.sh```](https://github.com/jbox-web/redmine_git_hosting/blob/devel/contrib/scripts/sidekiq_git_hosting.sh) is provided by the plugin.

You should place this script in Redmine user's home bin dir like : ```/home/redmine/bin/sidekiq_git_hosting.sh```.

Normally the Redmine user's bin directory should be in the PATH.

If not, add this in /home/redmine/.profile :

    # Set PATH so it includes user's private bin if it exists
    if [ -d "$HOME/bin" ] ; then
      PATH="$HOME/bin:$PATH"
    fi
