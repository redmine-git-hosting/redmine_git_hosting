---
title: A new reborn
layout: post-news
category: news
---

A new '**devel**' branch has been pushed to Github.

This new version of the plugin brings a lot of changes :

* remove Redmine 1.x support
* remove Rails 2.x support
* remove Ruby 1.8.x support
* replace Rails Observers by Active Record Callbacks
* replace 'Gitolite home made interface' by Gitolite gem (https://github.com/jbox-web/gitolite)
* lots of code cleanup
* lots of bugfixes
* add Sidekiq async tasks
* add Git mailing lists notifications
* add Default branch selection
* add Automatic Repository Initialization
* add Git Revision Download
* add README Preview
* [Add repository "config" keys management](https://github.com/jbox-web/redmine_git_hosting/issues/78)
* add Improved Repository Statistics
* add Github Issues Sync
* add Browse Archived Repositories
* add Bootstrap CSS
* add Font Awesome icons


This branch becomes the default branch and replaces the 'master' branch.

The 'master' branch has been renamed to 'v0.6' and is kept as archive.

The 'v0.6' branch will be no longer supported.

A new 'v0.7' branch will be created soon.
