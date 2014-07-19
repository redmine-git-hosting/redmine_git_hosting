---
layout: default
title: Step by Step migration
---

### {{ page.title }}
***

If you're upgrading from 0.6 version (or older) you should follow these steps :

Before updating the plugin, stop Redmine!

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
