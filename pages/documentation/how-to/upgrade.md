---
title: How To Upgrade
permalink: /how-to/upgrade/
---

{{ site.data.callouts.alertwarning }}
  Before upgrading the plugin, stop Redmine!
{{ site.data.callouts.end }}

    root$ su - redmine

    # Update Redmine Gitolite Hosting
    redmine$ cd REDMINE_ROOT/plugins/redmine_git_hosting
    redmine$ git fetch -p
    redmine$ git checkout {{ site.data.project.release.version }}

    # Update Bootstrap Kit
    redmine$ cd REDMINE_ROOT/plugins/redmine_bootstrap_kit
    redmine$ git fetch -p
    redmine$ git checkout 0.2.4

    # Install gems and run migrations
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without development test
    redmine$ bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_git_hosting
