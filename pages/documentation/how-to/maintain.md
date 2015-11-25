---
title: How To Maintain
permalink: /how-to/maintain/
---

**Note that all these commands must be run as *redmine* user**.


#### Resynchronization of Gitolite configuration
***

To fixup the Gitolite configuration file, execute :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production rake redmine_git_hosting:update_repositories


#### Fetch changesets
***

To fetch changesets for all repositories manually, execute :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production rake redmine_git_hosting:fetch_changesets


#### Restore/update plugin settings
***

To restore/update your plugin settings, set you current settings in ```settings.yml``` file (```init.rb``` for RedmineGitHosting < 1.2), then execute :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production rake redmine_git_hosting:restore_default_settings


#### Purge expired repositories from Recycle Bin
***

To purge expired repositories from Recycle Bin, execute :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production rake redmine_git_hosting:purge_recycle_bin


#### Check repositories uniqueness
***

To check repositories uniqueness before switching from Flat storage organization to Hierarchical organization execute :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production rake redmine_git_hosting:check_repository_uniqueness


#### Install hooks
***

To install/update hook files on Gitolite side execute :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production rake redmine_git_hosting:install_hook_files

To install/update hook parameters on Gitolite side execute :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production rake redmine_git_hosting:install_hook_parameters

To install/update both hook files and parameters on Gitolite side execute :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production rake redmine_git_hosting:install_gitolite_hooks


#### Empty Recycle Bin Periodically
***

Whenever a Redmine ```fetch_changesets()``` operation is executed (i.e. a call to ```http://REDMINE_ROOT/sys/fetch_changesets?key=xxx``` with curl or wget in a cron task), this plugin will check the Recycle Bin to make sure that repositories placed here (during delete operations) will be expired and removed.
