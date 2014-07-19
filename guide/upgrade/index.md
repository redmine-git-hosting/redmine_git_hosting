---
layout: default
title: Step by Step upgrade
---

### {{ page.title }}
***

    ## Before update the plugin, stop Redmine!

    root$ su - redmine

    redmine$ cd REDMINE_ROOT/plugins/redmine_git_hosting
    redmine$ git fetch
    redmine$ git checkout {{ site.data.project.release.version }}
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without development test
    redmine$ RAILS_ENV=production NAME=redmine_git_hosting rake redmine:plugins:migrate

    ## After update the plugin, start Redmine!
