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
    redmine$ git checkout master
    # latest release version is broken, use master branch to next version has been released!
    # redmine$ git checkout {{ site.data.project.release.version }}

    # Update additionals plugin
    redmine$ cd REDMINE_ROOT/plugins/additionals
    redmine$ git fetch -p
    redmine$ git checkout 3.0.5.2

    # Install gems and run migrations
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without development test
    redmine$ bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_git_hosting
