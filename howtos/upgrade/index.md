---
layout: default
title: How To Upgrade
---

### Step by Step upgrade

<div class="alert alert-warning" role="alert">Before update the plugin, stop Redmine!</div>

    root$ su - redmine

    redmine$ cd REDMINE_ROOT/plugins/redmine_git_hosting
    redmine$ git fetch -p
    redmine$ git checkout {{ site.data.project.release.version }}
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without development test
    redmine$ bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_git_hosting

<div id="toc">
</div>
