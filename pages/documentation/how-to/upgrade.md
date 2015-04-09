---
title: How To Upgrade
permalink: /how-to/upgrade/
---

{{ site.data.callouts.alertwarning }}
  Before upgrading the plugin, stop Redmine!
{{ site.data.callouts.end }}

    root$ su - redmine

    redmine$ cd REDMINE_ROOT/plugins/redmine_git_hosting
    redmine$ git fetch -p
    redmine$ git checkout {{ site.data.project.release.version }}
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without development test
    redmine$ bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_git_hosting
