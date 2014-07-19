---
layout: default
title: Release Notes
---

<div id="toc">
</div>


### Release Notes
***

#### Release 0.8

**Date   :** Pending

**Download :** [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.8.0)

**Status :** Beta

**Changelog :**

* Big refactoring of GitoliteWrapper (thanks Oliver Günther)
* Switch to [gitolite-rugged](https://github.com/oliverguenther/gitolite-rugged) (thanks Oliver Günther)
* Puts DownloadGitRevision logic in Service object
* Puts Hooks logic in Service object
* Add unique indexes in database
* Add SSH key fingerprint field
* Fix SystemStackError (stack level too deep) when updating DeploymentCredentials
* Fix [#199](https://github.com/jbox-web/redmine_git_hosting/issues/199) (unique_repo_identifier and hierarchical_organisation are now combined)
* Fix [#223](https://github.com/jbox-web/redmine_git_hosting/pull/223) (fix https:// notifications if TLSvX is mandatory)
* [Support for branch permission / protected branches](https://github.com/jbox-web/redmine_git_hosting/issues/86)
* Purge RecycleBin on fetch_changesets ([Configuration notes]({{ site.baseurl }}/configuration/notes/#empty-recycle-bin-periodically))
* Bump to last version of Git Multimail hook
* Bump ZeroClipboard to version v2.1.1
* Bump Highcharts to version 4.0.3
* Various other fixes

**Notes :**

Thanks to the work of Oliver Günther (really thank you), the plugin is now a lot more simple in many ways :

* the plugin is scriptless : no more need of ```gitolite_scripts_dir``` and shell scripts to wrap calls to sudo. Now, the only required dir is the ```gitolite_temp_dir``` to clone the Gitolite admin repository.
* SSH keys are stored in Gitolite in a directory tree under ```ssh_keys```. No more need of timestamped key name :)

Example :


    gitolite-admin.git/
    ├── conf
    │   └── gitolite.conf
    └── keydir
        ├── redmine_git_hosting
        │   ├── redmine_admin_1
        │   │   └── redmine_my_key
        │   │       └── redmine_admin_1.pub
        │   └── redmine_admin_1_deploy_key_1
        │       └── redmine_deploy_key_1
        │           └── redmine_admin_1_deploy_key_1.pub
        └── redmine_gitolite_admin_id_rsa.pub


**For the braves :**

I need testers for testing this version and specially the migration from 0.7.x. If you're interested git clone the devel branch and test it ! :)

**Do this in a test environment ! I won't be responsible if you break things on your production installation !**

*You can use a Virtual Machine to clone your production environment then play the migration.*

But don't afraid, the plugin is very stable and at least I can say that it works for me in an awesome way :)

This is my configuration :

    Environment:
      Redmine version                2.5.0.stable
      Ruby version                   2.0.0-p451 (2014-02-24) [x86_64-linux]
      Rails version                  3.2.17
      Environment                    development
      Database adapter               Mysql2
    SCM:
      Subversion                     1.6.17
      Mercurial                      2.2.2
      Git                            1.9.1
      Filesystem
    Redmine plugins:
      redmine_bootstrap_kit          0.1
      redmine_git_hosting            0.8-devel
      redmine_sidekiq                2.0.0

    Sudo version is 1.8.5p2 (but I don't think we should care of it now)
    Debian Wheezy 7.5
    Gitolite v3.5.3.1-11-g8f1fd84


To test the devel branch :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT/plugins
    redmine$ git clone https://github.com/ogom/redmine_sidekiq.git
    redmine$ git clone https://github.com/jbox-web/redmine_bootstrap_kit.git
    redmine$ git clone https://github.com/jbox-web/redmine_git_hosting.git
    redmine$ cd redmine_git_hosting/
    redmine$ git checkout devel
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without nothing

    ## IMPORTANT !
    ## Do this before any Rails migration !
    ## Some migration files has been renumbered (missing digit)
    redmine$ RAILS_ENV=production rake redmine_git_hosting:fix_migration_numbers

    ## Then do last migrations
    redmine$ RAILS_ENV=production NAME=redmine_git_hosting rake redmine:plugins:migrate

    ## Then reset SSH keys identifier (yes, again)
    redmine$ RAILS_ENV=production rake redmine_git_hosting:rename_ssh_keys


You can also play RSpec tests :

    ## Copy the RSpec helper :
    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ mkdir spec
    redmine$ cp plugins/redmine_git_hosting/spec/root_spec_helper.rb spec/spec_helper.rb

    ## Install and start Zeus
    redmine$ gem install zeus
    redmine$ zeus start

    ## Then in an other console :
    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ zeus rspec plugins/redmine_git_hosting/spec/

    ## And watch the tests passing :)

    ## To generate SimpleCov reports (or to test without installing Zeus) :
    redmine$ rspec plugins/redmine_git_hosting/spec/

***

#### Release 0.7.6

**Date :** Jul 17, 2014

**Download :** [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.6)

**Status :** Stable

**Changelog :**

* Bump to jbox-gitolite 1.2.3 which depends on [gitlab-grit 2.7.0](https://github.com/gitlabhq/grit/blob/master/History.txt)
* Fix [#207](https://github.com/jbox-web/redmine_git_hosting/issues/207) (gitolite-admin doesn't sync anymore) and his brothers

***

#### Release 0.7.5

**Date :** Jul 14, 2014

**Download :** [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.5)

**Status :** Stable

**Changelog :**

* Fix [#226](https://github.com/jbox-web/redmine_git_hosting/issues/226) (unable to download revision if branch has a '/' in the name)
* Fix [#230](https://github.com/jbox-web/redmine_git_hosting/issues/230) (Unwanted access to gitolite-admin repository)

***

#### Release 0.7.4

**Date :** Jul 4, 2014

**Download :** [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.4)

**Status :** Stable

**Changelog :**

* Fix [#184](https://github.com/jbox-web/redmine_git_hosting/issues/184 ) (truncated Bootstrap Switches)
* Fix [#211](https://github.com/jbox-web/redmine_git_hosting/issues/211) (mixed up dates in contributors statistics graph)
* Fix [#215](https://github.com/jbox-web/redmine_git_hosting/issues/215) (application.css conflicts)
* Fix [#225](https://github.com/jbox-web/redmine_git_hosting/issues/225) (unable to set new repository deployment credentials)
* Set extra_info field when auto-creating repo with project

***

#### Release 0.7.3

**Date :** June 11, 2014

**Download :** [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.3)

**Changelog :**

* Fix [#144](https://github.com/jbox-web/redmine_git_hosting/issues/144) (redcarpet dependency)
* Bump to jbox-gitolite 1.2.2
* Fix files changements in Github payload (files added, deleted, modified)
* Use repository name in Github payload
* Add pusher informations in Github payload
* Show Redmine fields in repository/edit
* Fix [#186](https://github.com/jbox-web/redmine_git_hosting/issues/186) (post-receive doesn't pass multiple lines through from STDIN)
* Fetch changesets after repository creation/restore
* Fix repository content overwrite on repo creation with README file and repository not empty

**Notes :**

You're invited to take a look at this [post](https://github.com/jbox-web/redmine_git_hosting/issues/199).

***

#### Release 0.7.2

**Date :** April 16, 2014

**Download :** [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.2)

**Changelog :**

* Fix [#160](https://github.com/jbox-web/redmine_git_hosting/issues/160)
* Fix [#169](https://github.com/jbox-web/redmine_git_hosting/issues/169)

***

#### Release 0.7.1

**Date :** April 14, 2014

**Download :** [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.1)

**Changelog :**

* Remove ENV['HOME'] dependency
* Remove Git config file dependency
* Remove SSH config file dependency
* Fix log redirection on Automatic Repository Initialization
* Fix plugin portability (use env instead of export)
* Fix layout bug in header navigation ([#162](https://github.com/jbox-web/redmine_git_hosting/pull/162)) (thanks soeren-helbig)
* Fix projects update on locking/unlocking user
* Various small fixes
* Use last version of [jbox-gitolite](http://rubygems.org/gems/jbox-gitolite) gem (1.1.11)

***

#### Release 0.7.0

**Date :** April 2, 2014

**Download :** [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.7.0)

**Changelog :**

* remove Redmine 1.x support
* remove Rails 2.x support
* remove Ruby 1.8.x support
* replace Rails Observers by Active Record Callbacks
* replace 'Gitolite home made interface' by Gitolite gem (https://github.com/jbox-web/gitolite)
* lots of code cleanup
* lots of bug fixes
* add [Sidekiq async jobs]({{ site.baseurl }}/features/#sidekiq-asynchronous-jobs)
* add [Git mailing lists]({{ site.baseurl }}/features/#git-mailing-lists)
* add [Default branch selection]({{ site.baseurl }}/features/#default-branch-selection)
* add [Automatic Repository Initialization]({{ site.baseurl }}/features/#automatic-repository-initialization)
* add [Git Revision Download]({{ site.baseurl }}/features/#git-revision-download)
* add [README preview]({{ site.baseurl }}/features/#readme-preview)
* add [Repository “config” keys management]({{ site.baseurl }}/features/#git-config-keys-management)
* add [Improved Repository Statistics]({{ site.baseurl }}/features/#improved-repository-statistics)
* add [Github Issues Sync]({{ site.baseurl }}/features/#github-issues-sync)
* add [Browse Archived Repositories]({{ site.baseurl }}/features/#browse-archived-repositories)
* add Bootstrap CSS
* add Font Awesome icons

***

#### Release 0.6.3

**Date :** February 23, 2014

**Download :** [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.6.3)

**Changelog :**

This is a bugfix release.

This is the last release of the 0.6.x branch.

The 'v0.6' is kept as archive and will be no longer supported.

***

#### Release 0.6.2

**Date :** July 28, 2013

**Download :** [here](https://github.com/jbox-web/redmine_git_hosting/releases/tag/0.6.2)

**Changelog :**

This is a security and bugfix release.

This releases fixes a high risk vulnerability, allowing an attacker to gain shell access to the server (CVE-2013-4663).

We strongly advise you to update your plugin!

***

#### Release 0.5.2x

**Date :** never released

**Download :** [here](https://github.com/kubitron/redmine_git_hosting/)

**Changelog :**

This is a bug-fix release.

* Fixed a migration problem with PostGreSQL (for uninstalling).
* Fix to allow validations to fail properly on Project creation for Redmine < 1.4
* Fix to prevent repository creation from stealing preexisting repositories in gitolite (which could happen under specialized circumstances).
* Fix to handle old versions of sudo (< 1.7.3) during repair of the administrative key
* Fix to preserve other administrative keys in the gitolite configuration file.  Previously, the plugin would delete all but the first one.  This fix is useful for people who want to have separate administrative keys for access to the gitolite config file.
* Fixed weird behavior on Repository page when using multiple repos/project.  Showed up when on non-default repo when trying to switch to branch other than master.  Would switch back to default repository.

***

#### Release 0.5.1x

**Date:** October 31, 2012

**Download :** [here](https://github.com/kubitron/redmine_git_hosting/tree/0.5.1x)

**Changelog :**

This is a bug-fix release.

* Post-Receive URLs should now work with SSL (i.e. URLs of the form "https://xxx")
* Additional patches for backward compatibility with ChiliProject/Redmine < 1.4. In this category was a problem with editing Git repo parameters as well as a minor bug that caused problems with adding members to projects that didn't have a Git repo.
* Additional patches to support Ruby 1.9.x.  Includes fix to post-receive hook and change in meaning of Module#instance_methods.
* Patched installation so that can install Redmine from *scratch* (i.e. run `rake db:migrate` on empty DB) with plugin already in place.
* Latest migration should now work with PostGreSQL.  This was broken in 0.5.0x.

***

#### Release 0.5.0x

**Date :** October 3, 2012

**Download :** [here](https://github.com/kubitron/redmine_git_hosting/tree/0.5.0x)

**Changelog :**

This is a feature release.

* New : Compatibility with Redmine 1.4
* Fix : Uninstall of plugin should work properly now.
* Fix : Problems with patching on some installations should be fixed now (introduced in a recent revision).

***

#### Release 0.4.6x

**Date :** August 22, 2012

**Download :** [here](https://github.com/kubitron/redmine_git_hosting/tree/0.4.6x)

**Changelog :**

This is a feature release.

* New: Added Deployment Credentials, which are public keys associated directly with a repository rather
than through a user.  These credentials can be created directly from the repository settings page.  Since
they are named (like other public keys), they can be reused for other repositories, if desired.  Note
that only **managers** (or **administrators**) can create deployment credentials (or deployment keys).  Further, deployment keys and credentials are owned by the original creator and appear in their "my account" page.

* New : Key validation and uniqueness.  The format, properties, and uniqueness of keys are validated before allowing them to be saved.  Note that actual keys must be unique across a whole gitolite installation (otherwise the access control mechanism doesn't work).  At the moment, this validation allows keys of type "ssh-rsa" and "ssh-dss".
* New : Ability to utilize alternate gitolite configuration file.
* New : handle archiving of projects.  Archived projects stay in the gitolite repository but are deactivated in the gitolite config file.  All Redmine keys are removed and replaced with a token key called "redmine_archived_project".
* New : Post-receive URLs configured from a repository settings page.  When commits occur, configured URLs will be POSTed with json information about the commit, roughly in the same format as github commits.  The POSTed payload is described here: http://help.github.com/post-receive-hooks/.
* New : Repository mirrors have more configuration options.  Rather than forcing the remote repository to be a complete mirror of the local repository (i.e. --mirror), repository mirrors can now specific an explicit reference specification for which branches to update and/or select whether to force update or require nothing more than a fast-forward.
* Fix : Change in login name on User settings screen properly changes keys in keydir.
* Fix : Fixed cases in which delete of user from project ACL and delete of user didn't clean up gitolite.conf
* Fix : Fixed problem with failed validation in user settings screen.
* Fix : Remove extra control characters (such as line breaks) as well as leading and trailing whitespace in public keys
* Fix : Validations for public keys now reflected back to the user interface.
* Fix : Deselection of repository module now has same effect as archiving project. The repository is marked in gitolite.conf as "redmine_disabled_project".  When project repository module is re-enabled, the repository is reconnected automatically.

Prior to this, repository module deselection was treated inconsistently.

***

#### Release 0.4.5x

**Date :** April 23, 2012

**Download :** [here](https://github.com/kubitron/redmine_git_hosting/tree/0.4.5x)

**Changelog :**

This is a bug-fix release.

* Fixed missed case for compatibility with Redmine 1.1-Stable.  This patch allows the mirror functionality to work.
* Fixed bad interaction between cron cleanup of /tmp and access to gitolite-admin repository in /tmp.  Behavior could cause user keys to appear to be deleted, even though they remain in the redmine database.  This behavior has likely been a part of this plugin since before this branch was forked (pre 0.4.2).

***

#### Release 0.4.4x

**Date :** April 1, 2012

**Download :** [here](https://github.com/kubitron/redmine_git_hosting/tree/0.4.4x)

**Changelog :**

This release includes feature enhancements and bug fixes.

Compatibility with Redmine 1.1-Stable. A couple of patches were included to permit this plugin to work with older Redmine releases.

* New settings to configure the /tmp and /bin directories (**gitTemporaryDir** and **gitScriptDir** respectively).
* New settings for the default "Daemon Mode" (**gitDaemonDefault**), "SmartHTTP mode" (**gitHttpDefault**), and "Notify CIA mode" (**gitNotifyCIADefault**) for new repositories.
* Better script support for installing scripts in the /bin directory.
* Updated installation instructions in the README.
* Better recovery from loss of administrative key in gitolite -- assuming use of gitolite version >= 2.0.3.
* Fix : Improvements to repository mirror support.
* Fix : Support '@' in user names for http access (externally converted to '%40').
* Fix : Syntax fixes to allow use of Ruby 1.9.
* Fix : Support for git-daemon now working correctly.  The "daemon" key was not being removed correctly and projectgs with "daemon" support were not being deleted.
* Fix : Better handling of null-buffer condition in smart-http.
* Fix : Fixed language tags in localization files.

***

#### Release 0.4.3x

**Date :** February 1, 2012

**Download :** [here](https://github.com/kubitron/redmine_git_hosting/tree/0.4.3x)

**Changelog :**

This release includes feature enhancements and bug fixes.

This release includes a complete rewrite of the update_repository() functionality with an eye toward better resilience.

This code will automatically recover from a variety of weird failure modes which originally could occur.
Further, execution of fetch_changesets will resynchronize the gitolite.conf file, fixing any inconsistencies that might have crept into this file.
Co-existence of Redmine-managed and non-redmine-managed repositories in the gitolite.conf file is supported. Some specific things that will be resynched :

* Missing keys will be added and unused keys will be removed from the keydir directory.
* Entries in gitolite.conf will be updated with new path information as necessary.
* If proper setting is selected, orphan repo entries will be removed from gitolite.conf file, and the repositories themselves will be moved to the new recycle bin in the gitolite homedirectory.
* Hooks will be checked and repaired as necessary.

This code is now explicitly compatible with Redmine 1.3-stable.

* Added user-edit screen to allow administrator to examine and edit users keys.
* Git Server parameter now supports a port specification.
* Other bug fuxes: mirrors now report status properly.

***

#### Release 0.4.2x

**Date :** December 1, 2011

**Download :** [here](https://github.com/kubitron/redmine_git_hosting/tree/0.4.2x)

**Changelog :**

This release includes feature enhancements and bug fixes.

* One of the most important aspects of this release is a fix for the performance problems that plagued earlier versions of the plugin for post 1.2 Redmine. Fetch_changesets operations should now be possible.
* A second aspect is support for selinux.  Scripts have been placed into a separate /bin directory which is placed at the root of the plugin (i.e. REDMINE_ROOT/vendor/plugins/redmine_git_hosting/bin).  A set of rake tasks have been added to assist in installing selinux tags and pre-building scripts in the bin directory.
