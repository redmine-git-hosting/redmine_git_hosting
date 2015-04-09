---
title: How To Remove
permalink: /how-to/remove/
---

I'm sorry you didn't find any satisfaction in this plugin. If you want to remove it just follow the steps :

{{ site.data.callouts.alertwarning }}
  Before removing the plugin, stop Redmine!
{{ site.data.callouts.end }}

    root$ su - redmine

    redmine$ cd REDMINE_ROOT
    redmine$ bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_git_hosting VERSION=0
    redmine$ rm -rf REDMINE_ROOT/plugins/redmine_git_hosting
