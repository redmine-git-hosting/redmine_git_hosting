---
layout: default
title: News
group: navigation
weight: 1
---

#### **17/07/2014**

The **0.7.6** version is out!

You can download it [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.6) or see the changelog [here]({{ site.baseurl }}/about/release-notes/#release-076).

***

#### **14/07/2014**

The **0.7.5** version is out!

You can download it [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.5) or see the changelog [here]({{ site.baseurl }}/about/release-notes/#release-075).

***

#### **04/07/2014**

The **0.7.4** version is out!

You can download it [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.4) or see the changelog [here]({{ site.baseurl }}/about/release-notes/#release-074).

***

#### **11/06/2014**

The **0.7.3** version is out!

You can download it [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.3) or see the changelog [here]({{ site.baseurl }}/about/release-notes/#release-073).

***

For the next release (0.8) a lot of work has been done to :

* add RSpec tests
* add Travis job (to execute tests in Redmine context, done once for all :))
* clean up things (database type, associated behavior, etc...)
* refactor things (puts Hooks logic in Service objects and others)
* extract things (Redmine Bootstrap Kit, Font Awesome, JQuery Plugins)

You can see the passing tests suite here : https://travis-ci.org/jbox-web/redmine_git_hosting :)

Thanks to the tests suite I found some caveats in the plugin (**this is for all versions**).

I wrote a Request For Comment about [this](https://github.com/jbox-web/redmine_git_hosting/issues/199). You **must** read it before configure Redmine. Depending on your configuration you're exposed to weird side-effects (like repository not updated after commits...).

You're invited to give your opinion about this issue ;)

***

For the brave testers who wants to test the devel branch :

 * I had to rename some migration files due to some buggy names (a missing digit in the filename).
 * It includes a database migration that enforce database type (and latter in Rails, the fields validations)
 * It also includes RSpec tests so it comes with some other bug fixes that I didn't merge in 0.7.3.

So right after checkout the devel branch, (and before doing any database migration), you *must* run

    RAILS_ENV=production rake redmine_git_hosting:fix_migration_numbers

then

    RAILS_ENV=production rake redmine:plugins:migrate NAME=redmine_git_hosting

**Don't forget to backup your datas before!! (Gitolite repositories and Redmine database)**

***

#### **16/04/2014**

The **0.7.2** version is out!

You can download it [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.2) or see the changelog [here]({{ site.baseurl }}/about/release-notes/#release-072).

***

#### **14/04/2014**

The **0.7.1** version is out!

You can download it [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.1) or see the changelog [here]({{ site.baseurl }}/about/release-notes/#release-071).

***

#### **02/04/2014**

The **0.7** version is finally out!

You can download it [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.0) or see the changelog [here]({{ site.baseurl }}/about/release-notes/#release-070).

***

#### **07/03/2014**

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
* [Add repository “config” keys management](https://github.com/jbox-web/redmine_git_hosting/issues/78)
* add Improved Repository Statistics
* add Github Issues Sync
* add Browse Archived Repositories
* add Bootstrap CSS
* add Font Awesome icons

This branch becomes the default branch and replaces the 'master' branch.

The 'master' branch has been renamed to 'v0.6' and is kept as archive.

The 'v0.6' branch will be no longer supported.

A new 'v0.7' branch will be created soon.
