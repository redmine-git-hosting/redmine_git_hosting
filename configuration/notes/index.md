---
layout: default
title: Configuration notes
---

### {{ page.title }}
***

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

#### Resynchronization of Gitolite configuration

**Note that it is very important that these commands be run as *redmine***

To fixup the Gitolite configuration file, execute :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production rake redmine_git_hosting:update_repositories

To fetch changesets for all repositories manually, execute :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production rake redmine_git_hosting:fetch_changesets

To restore/update your plugin settings, set you current settings in ```init.rb``` file, then execute :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production rake redmine_git_hosting:restore_default_settings

To purge expired repositories from Recycle Bin, execute :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ RAILS_ENV=production rake redmine_git_hosting:purge_recycle_bin

***

#### Empty Recycle Bin Periodically

Whenever a Redmine ```fetch_changesets()``` operation is executed (i.e. a call to ```http://REDMINE_ROOT/sys/fetch_changesets?key=xxx``` with curl or wget in a cron task), this plugin will check the Recycle Bin to make sure that repositories placed here (during delete operations) will be expired and removed.

***

#### Sidekiq :: Concurrency

When running in Sidekiq mode, do **not** modify ```sidekiq.yaml```, particularly the ```concurrency``` parameter.

Tasks are async but cannot be parallels as we need to write in a file.

Hence the sidekiq worker is a one-queue worker and tasks are stacked **in order** in the queue.

Modifying the ```concurrency``` parameter would break the order of tasks and could lead to an inconsistent state of the Gitolite configuration file.

***

#### Placement and modification of executable scripts

<div class="alert alert-warning" role="alert">This only apply for Redmine Git Hosting version <strong>< 0.8</strong></div>

You may place the executable scripts anywhere in the filesystem.  The default location of the scripts is set with **:gitolite_script_dir**.

The default value :

    REDMINE_ROOT/plugins/redmine_git_hosting/bin         # Redmine 2.x

is a good location, especially if you have multiple simultaneous Redmine installations on the same host, since scripts are customized to each installation.

Thus, we **recommend** that you consider keeping the default placement. In this location, some maintainers may not wish to allow the plugin to re-write the scripts during execution -- hence the options to make scripts read-only.

Further, when SELinux is installed, the scripts are not writeable by default (because of SELinux tags), since changing them could be construed to be a security hole.

When the script directory is not writeable by the user running Redmine, you also cannot alter five of the settings on the settings page (since their alteration would require the regeneration of scripts).

These values are:

* **:gitolite_script_dir**
* **:gitolite_user**
* **:gitolite_ssh_private_key**
* **:gitolite_ssh_public_key**
* **:gitolite_server_port**

The settings page will make the fact that you cannot alter these values clear by marking that as *[Cannot change in current configuration]*.

In that case, the simplest way to change these values is to

**(1)** remove the old scripts

**(2)** alter the parameters on the settings page (after refreshing the settings page)

**(3)** then reinstalling scripts as discussed in step (8) of the installation instructions.

Scripts can be removed with:

    rake redmine_git_hosting:remove_scripts RAILS_ENV=production

***

#### SELinux Configuration

<div class="alert alert-warning" role="alert">This only apply for Redmine Git Hosting version <strong>< 0.8</strong></div>

This plugin can be configured to run with SELinux.  We have included a rakefile in ```tasks/selinux.rake``` to assist with installing with SELinux. You can execute one of the SELinux rake tasks (from the Redmine root).

For instance, the simplest option installs a SELinux configuration for both Redmine and the redmine_git_hosting plugin :

    rake selinux:install RAILS_ENV=production

This will generate the redmine_git_hosting binaries in ```./bin```, install a SELinux policy for these binaries (called ```redmine_git.pp```), then install a complete context for Redmine as follows :

**(1)** Most of Redmine will be marked with **public_content_rw_t**

**(2)** The dispatch files in ```Rails.root/public/dispatch.*``` will be marked with **httpd_sys_script_exec_t**

**(3)** The redmine_git_hosting binaries in ```Rails.root/vendor/plugins/redmine_git_hosting/bin``` will be labeled with **httpd_redmine_git_script_exec_t**, which has been crafted to allow the sudo behavior required by these binaries.

Note that this rake file has additional options.  For instance, you can specify multiple Redmine roots with regular expressions (not globbed expressions!) as follows (notice the use of double quotes) :

    rake selinux:install RAILS_ENV=production ROOT_PATTERN="/source/.*/redmine"

These additional options are documented in the ```selinux.rake``` file. Under normal operation, you will get one SELinux complaint about ```/bin/touch``` in your log each time that you visit the plugin settings page.

Once this plugin is placed under SELinux control, five of the redmine_git_hosting settings can not be modified from the settings page. They are :

* **:gitolite_script_dir**
* **:gitolite_user**
* **:gitolite_ssh_private_key**
* **:gitolite_ssh_public_key**
* **:gitolite_server_port**

The plugin settings page will make this clear.  One way to modify these options is to remove the old scripts, refresh the setting page, change options, then reinstall scripts. Specifically, you can
remove scripts with :

    rake selinux:redmine_git_hosting:remove_scripts RAILS_ENV=production

Scripts and SELinux policy/tags can be reinstalled with :

    rake selinux:redmine_git_hosting:install RAILS_ENV=production

One final comment : The SELinux policy exists in binary form as ```selinux/redmine_git.pp```. Should this policy need to be rebuilt, an additional rake task exists which will build the policy from ```selinux/redmine_git.te``` :

    rake selinux:redmine_git_hosting:build_policy RAILS_ENV=productinon


This task can be followed by the ```selinux:install``` task.

The rakefile and SELinux configuration has been primarily tested on Redhat Enterprise Linux version 6.x with Apache and fcgi. Other configurations may require slight tweaking.

<div id="toc">
</div>
