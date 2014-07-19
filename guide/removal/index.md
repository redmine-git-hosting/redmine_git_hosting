---
layout: default
title: Step by Step removal
---

### {{ page.title }}
***

I'm sorry you didn't find any satisfaction in this plugin.

If you want to remove it just follow the steps :

    ## Before removing the plugin, stop Redmine!

    root$ su - redmine

    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production NAME=redmine_git_hosting VERSION=0 rake redmine:plugins:migrate
    redmine$ rm -rf REDMINE_ROOT/plugins/redmine_git_hosting

    ## After removing the plugin, start Redmine!
