---
layout: default
title: Configuration notes
---


### Configuration notes

#### Repositories Storage Configuration Strategy

Redmine Git Hosting has 2 modes to store repositories in Gitolite :

* **hierarchical** : repositories will be stored in Gitolite into a hierarchy that mirrors the project hierarchy.

* **flat** : repositories will be stored in Gitolite directly under ```repository/```, regardless of the number and identity of any parents that they may have.

***

#### Interaction with non-Redmine Gitolite users

This plugin respects Gitolite repositories that are managed outside of Redmine or managed by both Redmine and non-Redmine users :

* Users other than **redmine_*** are left untouched and can be in projects by themselves or mixed in with projects managed by redmine.

* When a Redmine-managed project is deleted (with the **Delete Git Repository When Project Is Deleted** option enabled), its corresponding Git repository **will not be deleted/recycled** if there are non-Redmine users in the *gitolite.conf* file.

***

#### Empty Recycle Bin Periodically

Whenever a Redmine ```fetch_changesets()``` operation is executed (i.e. a call to ```http://REDMINE_ROOT/sys/fetch_changesets?key=xxx``` with curl or wget in a cron task), this plugin will check the Recycle Bin to make sure that repositories placed here (during delete operations) will be expired and removed.

***

#### Sidekiq :: Concurrency

When running in Sidekiq mode, do **not** modify ```sidekiq.yaml```, particularly the ```concurrency``` parameter.

Tasks are async but cannot be parallels as we need to write in a file.

Hence the sidekiq worker is a one-queue worker and tasks are stacked **in order** in the queue.

Modifying the ```concurrency``` parameter would break the order of tasks and could lead to an inconsistent state of the Gitolite configuration file.
