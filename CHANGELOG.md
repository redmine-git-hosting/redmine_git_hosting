## CHANGELOG

### 4.0.0

* compatible with Redmine 4 (drop Redmine 3.x support)
* drop redmine_bootstrap_kit required plugin
* requires additionals plugin for latest fontawesome, slim and deface support -> and better maintenance
* switch from haml to slim templates (because this is already used in additionals plugin)
* libraries high_charts and bootstrap are moved to this plugin (TODO: high_charts should be migrationed to charts.js, which comes with Redmine 4. Bootstrap should be drop to vanila redmine, to get better theme support)

### 1.2.3 - 2017-07-17

* Merge [#640](https://github.com/jbox-web/redmine_git_hosting/pull/640) ([Views] Fix typo while rendering partial repositories/download_revision)
* Merge [#646](https://github.com/jbox-web/redmine_git_hosting/pull/646) (Fix compatibility with Redmine 3.3)
* Merge [#663](https://github.com/jbox-web/redmine_git_hosting/pull/663) ([Core] Fix installation of Gitolite3 hooks)
* Improve custom Gitolite hook loading (see `custom_hooks.rb.example` at the root of the project)
* Fix plugin icon with Redmine 3.4.x
* Fix author url in sub-uri mode
* Check if hook's permissions has changed
* Catch Errno::ENOENT exceptions when installing custom hooks
* Add logs for well installed Gitolite hooks

### 1.2.2 - 2016-12-31

* Fix [#472](https://github.com/jbox-web/redmine_git_hosting/issues/472) ([Views] 404 on the "My public keys" link in the user panel)
* Fix [#526](https://github.com/jbox-web/redmine_git_hosting/issues/526) ([Core] Plugin breaks if gitolite user == redmine user)
* Fix [#551](https://github.com/jbox-web/redmine_git_hosting/issues/551) ([Core] Make Sidekiq truly optional)
* Fix [#576](https://github.com/jbox-web/redmine_git_hosting/issues/576) ([Models] Can't add Git Config Key)
* Fix [#630](https://github.com/jbox-web/redmine_git_hosting/issues/630) ([Core] Use "gitolite query-rc" to get Gitolite variables)
* Fix [#632](https://github.com/jbox-web/redmine_git_hosting/issues/632) ([Core] Mirroring does not work on git push)
* Merge [#581](https://github.com/jbox-web/redmine_git_hosting/pull/581) (Fix [#472](https://github.com/jbox-web/redmine_git_hosting/issues/472) by amelentjev)
* Merge [#621](https://github.com/jbox-web/redmine_git_hosting/pull/621) ([Routes] Mount grack under http_server_subdir)
* Merge [#624](https://github.com/jbox-web/redmine_git_hosting/pull/624) ([Translations] Add Spanish translation)
* Merge [#634](https://github.com/jbox-web/redmine_git_hosting/pull/634) ([Views] Added missing mandatory param for partial repositories/download_revision)
* Merge [#636](https://github.com/jbox-web/redmine_git_hosting/pull/636) ([Doc] "Remove user ID from Gitolite identifier" requires a restart)
* Fix repo url in Gitolite hooks
* Fix nil data case when loading custom settings from empty file
* Allow to load plugin settings from a file in Redmine root (should ease deployment and upgrades)
* Fix wrong Repository Git objects count
* Add Russian translation
* Rename `redmine_git_hosting:restore_defaults` task to `redmine_git_hosting:update_settings`
* Add Rake task `redmine_git_hosting:dump_settings` to dump plugin settings in console

### 1.2.1 - 2016-07-25

* Fix [#524](https://github.com/jbox-web/redmine_git_hosting/issues/524) ([DB] Index too long)
* Fix [#533](https://github.com/jbox-web/redmine_git_hosting/issues/533) ([Views] About readme.md preview feature)
* Fix [#541](https://github.com/jbox-web/redmine_git_hosting/issues/541) ([Core] SSH/Gitolite server host on 1.2)
* Fix [#553](https://github.com/jbox-web/redmine_git_hosting/issues/553) ([Controllers] Protected branches user list never updated. Mass-assign warning.)
* Fix [#569](https://github.com/jbox-web/redmine_git_hosting/issues/569) ([Core] Connection refused when sshd doesn't listen on default port)
* Merge [#583](https://github.com/jbox-web/redmine_git_hosting/pull/583) ([Core] force UTF-8 encoding for tags and branches)
* Merge [#600](https://github.com/jbox-web/redmine_git_hosting/pull/600) ([Core] Improve performance)

### 1.2.0 - 2015-11-18

* Enhance protected branches permissions support : [#389](https://github.com/jbox-web/redmine_git_hosting/issues/389), [#414](https://github.com/jbox-web/redmine_git_hosting/issues/414)
* Add support for [Gitolite options](https://gitolite.com/gitolite/options.html) : [#415](https://github.com/jbox-web/redmine_git_hosting/issues/415)
* Enhance global repository access : [#465](https://github.com/jbox-web/redmine_git_hosting/issues/465). You can now choose if Redmine has RW access on all repositories.
* Improve validation of plugin settings. Validation errors are now displayed in the view.
* Use our own Rack implementation to render Gitolite hooks
* Fix [push over HTTP](http://redmine-git-hosting.io/troubleshooting/#hook-errors-while-pushing-over-https)
* Cleanup code/API
* Improve coding style
* Display contributors in plugins info page ;)

### 1.1.5 - 2015-11-18

* Fix wrong behavior of GoRedirectorController when project is private
* Update Redcarpet to latest version (3.3.2)

### 1.1.4 - 2015-10-01

* Merge [#505](https://github.com/jbox-web/redmine_git_hosting/pull/505) ([Core] Added an error message in case that something as broken the temp directory)
* Fix #<TypeError: no implicit conversion of nil into String> when triggers are enabled on PostReceiveUrls and pushing on a non-triggering branch
* Fix #<TypeError: no implicit conversion of nil into String> when triggers (refspec) are enabled on RepositoryMirrors and pushing on a non-triggering branch

### 1.1.3 - 2015-08-30

* Merge [#350](https://github.com/jbox-web/redmine_git_hosting/pull/350) ([Core] return [] if error occured on branches or tags check)
* Fix [#472](https://github.com/jbox-web/redmine_git_hosting/issues/472) ([Views] 404 on the "My public keys" link in the user panel when Redmine is installed in a subpath)
* Fix [#484](https://github.com/jbox-web/redmine_git_hosting/issues/484) ([Core] Error 500 on repository creation & edit)
* Fix [#501](https://github.com/jbox-web/redmine_git_hosting/issues/501) ([Controllers] Download Git Revision Archive for Anonymous user redirect to login page)
* Fix [#502](https://github.com/jbox-web/redmine_git_hosting/issues/502) ([Core] Issues with Git 1.7.1)

### 1.1.2 - 2015-08-21

* Fix [#459](https://github.com/jbox-web/redmine_git_hosting/issues/459) ([Install] Undefined method `urls_order' for #RepositoryGitExtra during migrations)
* Merge [#491](https://github.com/jbox-web/redmine_git_hosting/pull/491) ([Views] Fix css spacer bug for compatibility with core css)

### 1.1.1 - 2015-06-29

* Display Rugged infos in Config test tab
* Display Rugged features status (present/absent) in Config test tab
* Bump gitolite-rugged to v1.1.1 (Use HTTPs instead of Git protocol to download rugged gem)
* Add [#464](https://github.com/jbox-web/redmine_git_hosting/pull/464) ([Views] Fix display of git_annex urls)
* Add [#466](https://github.com/jbox-web/redmine_git_hosting/pull/466) ([Core] In case of git command failure, log the actual command line)

### 1.1.0 - 2015-06-06

* Add [#417](https://github.com/jbox-web/redmine_git_hosting/issues/417) ([Views] Define order of repository urls)
* Add [#426](https://github.com/jbox-web/redmine_git_hosting/issues/426) ([Views] Direct link to repository settings page on sidebar)
* Add [#427](https://github.com/jbox-web/redmine_git_hosting/issues/427) ([Views] Back to settings/repositories on repositories/edit page)
* Add [#431](https://github.com/jbox-web/redmine_git_hosting/issues/431) ([Core] Add support for Redmine/Gitolite splitted configuration)
* Add ```resync_ssh_keys``` Rake command (thx Hugodby)
* Use ```Etc``` Ruby module to find out Gitolite user home dir (instead of doing ```eval``` with sudo)
* Rework mirroring key installation
* Flush internal cached variables when settings change
* Add a jump box to switch repositories in edit view
* Fix RepositoryMirror regex (allow dashes in user name part)
* Bump gitolite-rugged to v1.1.0 (bundled with rugged and libgit2 in version 0.22.2)
* Remove temp directory when Gitolite settings change (it will be recloned with the right settings)
* Add 'Move repository' feature : you can now move repositories accross projects
* Add unique index on fingerprint field
* Various small fixes

### 1.0.7 - 2015-06-06

* Fix [#450](https://github.com/jbox-web/redmine_git_hosting/issues/450) (Github webhook return 404 error)
* Display Rugged infos in Config test tab

### 1.0.6 - 2015-06-04

* Validate that people don't reuse Gitolite Admin key

### 1.0.5 - 2015-05-31

* Fix [#418](https://github.com/jbox-web/redmine_git_hosting/issues/418) ([Rugged] On delete deploy key: Rugged::NetworkError)
* Fix [#430](https://github.com/jbox-web/redmine_git_hosting/issues/430) ([User] Error when trying to update user details)

### 1.0.4 - 2015-04-10

* Fix [#404](https://github.com/jbox-web/redmine_git_hosting/issues/404) ([Git cache] "Until next commit" param is broken for Redis adapter)
* Fix [#406](https://github.com/jbox-web/redmine_git_hosting/issues/406) ([Protected Branch] Protected Branch Name Must be Unique Across Projects)
* Fix [#407](https://github.com/jbox-web/redmine_git_hosting/issues/407) ([Protected Branch] 500 Error rearranging protected branches)
* Fix [#413](https://github.com/jbox-web/redmine_git_hosting/issues/413) ([Repository view] Missing repo source in repo instructions)
* Add [#410](https://github.com/jbox-web/redmine_git_hosting/issues/410) ([Protected Branch] Gray protected branches if not enabled by repo flag)

### 1.0.3 - 2015-04-01

* Fix [#322](https://github.com/jbox-web/redmine_git_hosting/issues/322) ([Statistics view] PG::GroupingError: ERROR: column "changesets.id" must appear in the GROUP BY clause)
* Fix [#334](https://github.com/jbox-web/redmine_git_hosting/issues/334) ([Translations] English locale file still contains French messages)
* Fix [#383](https://github.com/jbox-web/redmine_git_hosting/issues/383) ([Statistics view] Mysql2::Error: Unknown column 'changes.commit_date' in 'order clause')
* Fix [#384](https://github.com/jbox-web/redmine_git_hosting/issues/384) (```rake redmine_git_hosting:fetch_changesets``` doesn't clear cache)
* Fix [#385](https://github.com/jbox-web/redmine_git_hosting/issues/385) ([Statistics view] Commits and changes lines are shifted)
* Fix [#401](https://github.com/jbox-web/redmine_git_hosting/issues/401) ([Git cache] "Until next commit" param is broken)
* DRY controllers
* Improve permissions checking
* Improve tests on controllers
* DRY views
* Rework Repository URLs rendering
* Extract some views helpers to Redmine Bootstrap Kit plugin
* Fix TagIt loading for ProtectedBranches
* Add the '@all' repository in ```gitolite.conf``` when auto create README file is enabled (from [#338](https://github.com/jbox-web/redmine_git_hosting/issues/338))
* Remove useless ```:gitolite_log_split``` params
* Improve GitCache lookup performance (for Database and Redis adapters)
* Improve Statistics rendering performance
* Test the plugin with Redmine latest stable branch to prevent/anticipate [this kind of bug](https://github.com/jbox-web/redmine_git_hosting/issues/387)
* Update install doc
* Update migration doc

**Notes :**

* Before update Redmine Git Hosting plugin you **must** update Redmine Bootstrap Kit plugin to version **0.2.3** :

```sh
# Update Redmine Bootstrap Kit
redmine$ cd REDMINE_ROOT/plugins/redmine_bootstrap_kit
redmine$ git fetch -p
redmine$ git checkout 0.2.3

# Cleanup plugins assets dir
redmine$ cd REDMINE_ROOT/public/plugin_assets
redmine$ rm -rf *
```

* Deployment keys permissions has been renamed (from ```*_deployment_keys``` to ```*_repository_deployment_credentials```) so you will have to restore these permissions in *Administration -> Roles*.

### 1.0.2 - 2015-03-14

* Merge [#348](https://github.com/jbox-web/redmine_git_hosting/pull/348) (Use Redmine setting for Git command)
* Fix [#345](https://github.com/jbox-web/redmine_git_hosting/issues/345) (HTTPS Push, Popen : wrong number of arguments, Ruby 1.9 compatibility)
* Fix [#351](https://github.com/jbox-web/redmine_git_hosting/issues/351) (undefined method `split' for nil:NilClass)
* Fix [#354](https://github.com/jbox-web/redmine_git_hosting/issues/354) (Input string is longer than NAMEDATALEN / index too long)
* Fix [#358](https://github.com/jbox-web/redmine_git_hosting/issues/358) (undefined method `join' for nil:NilClass)
* Fix [#364](https://github.com/jbox-web/redmine_git_hosting/issues/364) (Gitolite hook silently fails on HTTP redirect)
* Fix [#368](https://github.com/jbox-web/redmine_git_hosting/issues/368) ("My public keys" link is still missing the subpath)
* Fix [#375](https://github.com/jbox-web/redmine_git_hosting/issues/375) (SmartHTTP link is not properly generated when Redmine is installed in a sub-path)
* Fix [#377](https://github.com/jbox-web/redmine_git_hosting/issues/377) ("Git user is able to sudo to Redmine user?" fails with non-login shell)
* Fix "undefined method `identifier' for nil:NilClass" when migrating to v1
* Add Redmine 3.x compatibility
* Update Redmine installer script for Travis builds
* Use Redmine Bootstrap Kit - TagIt helper
* Use Redmine Bootstrap Kit - BootstrapSwitch helper

**Notes :**

* Depending on your Redmine version (2.x/3.x) you'll have to comment/uncomment the right lines in the plugin's ```Gemfile```

* Before update Redmine Git Hosting plugin you **must** update Redmine Bootstrap Kit plugin to version **0.2.2** :

```sh
# Update Redmine Bootstrap Kit
redmine$ cd REDMINE_ROOT/plugins/redmine_bootstrap_kit
redmine$ git fetch -p
redmine$ git checkout 0.2.2

# Cleanup plugins assets dir
redmine$ cd REDMINE_ROOT/public/plugin_assets
redmine$ rm -rf *
```

* Since [support of Ruby 1.9.x has ended](https://www.ruby-lang.org/en/news/2014/01/10/ruby-1-9-3-will-end-on-2015/), **we won't support Ruby 1.9.x anymore**.
We highly recommend that you upgrade to Ruby 2.1 or 2.0.0 as soon as possible.

### 1.0.1 - 2015-02-23

* Fix archive name in DownloadGitRevision
* Fix [#331](https://github.com/jbox-web/redmine_git_hosting/issues/331) (Internal Server Error on user details)
* Fix [#335](https://github.com/jbox-web/redmine_git_hosting/issues/335) (gitolite-rugged can handle subdirectories for config file, just pass them)
* Fix [#336](https://github.com/jbox-web/redmine_git_hosting/issues/336) (TypeError no implicit conversion of nil into Array, fix 404/500 errors in repository views)
* Fix [#340](https://github.com/jbox-web/redmine_git_hosting/issues/340) (Invalid public key link)
* Fix [#344](https://github.com/jbox-web/redmine_git_hosting/issues/344) (Add a warning if Repository::Xitolite is disabled on repository auto-create)

* Add link to repositories in Project overview

### 1.0.0 - 2015-01-26

This new version is the first one of the v1.0 branch!

For this version the major part of the code has be rewritten to be cleaner and easier to debug.
It also brings some new features and fixes a lot of bugs.

There are some major changes that should solve a lot of issues :

* The plugin doesn't override ```Repository::Git``` object anymore. Instead it introduces a new type of repository in Redmine : ```Gitolite``` repositories.
That means that you can have standard Redmine Git repositories as before and Gitolite repositories in the **same time**.
*Note that only Gitolite repositories have advanced features (mirrors, post urls, etc...).*

* The second major change concerns the Storage strategy already discussed [here](https://github.com/jbox-web/redmine_git_hosting/issues/199).
```unique_repo_identifier``` and ```hierarchical_organisation``` are now combined in a single param : ```hierarchical_organisation```.

* And finally the third major change is the switch to [gitolite-rugged](https://github.com/oliverguenther/gitolite-rugged) thanks to Oliver Günther.

**Changes :**

* Big refactoring of GitoliteWrapper (thanks Oliver Günther)
* Switch to Gitlab Grack to provide Git SmartHTTP feature
* Add SSH key fingerprint field in database

**New features :**

* Export developer public ssh keys in Redmine REST API
* Export repository extras (mirrors, post receive urls, etc...) in Redmine REST API
* Add "go get" support for GoLang
* GitolitePlugins Sweepers and Extenders : to execute some actions after repository create/update/delete
* new GitCache adapters : Memcached and Redis (faster than the current database adapter)
* GitoliteHooks DSL to install your own Gitolite hooks globally
* Support for GitAnnex repositories
* [Support for branch permission / protected branches](https://github.com/jbox-web/redmine_git_hosting/issues/86)
* Add rake tasks for a fully automated install [#303](https://github.com/jbox-web/redmine_git_hosting/issues/303)

**Fixes :**

* Hooks URL should be configurable
* Fix [#223](https://github.com/jbox-web/redmine_git_hosting/pull/223) (fix https:// notifications if TLSvX is mandatory)
* Fix [#240](https://github.com/jbox-web/redmine_git_hosting/issues/240) (Allow modification of the gitolite-admin repository from a different location)
* Fix [#286](https://github.com/jbox-web/redmine_git_hosting/issues/286) (Link to "my public keys" is shown even if right is not granted)
* Fix [#310](https://github.com/jbox-web/redmine_git_hosting/issues/310) (compatibility with redmine_scm_creator plugin)
* Fix [#311](https://github.com/jbox-web/redmine_git_hosting/issues/311) (mirror repository URLs should permit dots in repository path)
* Purge RecycleBin on fetch_changesets ([Configuration notes]({{ site.baseurl }}/configuration/notes/#empty-recycle-bin-periodically))

**Other :**

* Bump to last version of Git Multimail hook
* Bump ZeroClipboard to version v2.1.1
* Bump Highcharts to version 4.0.3

**Notes :**

Thanks to the work of Oliver Günther (really thank you), the plugin is now a lot more simple in many ways :

* the plugin is scriptless : no more need of ```gitolite_scripts_dir``` and shell scripts to wrap calls to sudo. Now, the only required dir is the ```gitolite_temp_dir``` to clone the Gitolite admin repository.
* SSH keys are stored in Gitolite in a directory tree under ```ssh_keys```. No more need of timestamped key name :)

Example :

```sh
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
```

### 0.7.10 - 2015-01-26

* Fix [#324](https://github.com/jbox-web/redmine_git_hosting/issues/324) (Unable to flag repository as Main)
* Fix [#326](https://github.com/jbox-web/redmine_git_hosting/issues/326) (Error occurred while loading the routes definition)
* Fix [#329](https://github.com/jbox-web/redmine_git_hosting/issues/329) ("internal Error" when trying to edit a newly created repo)

**Notes :**

  **Important !**

  This is the last version of the v0.7 branch. **There won't be new releases under this branch**.

  That means that everyone should migrate to the new 1.0 version :)

  **Important !**

  Before migrating to the new 1.0 you **MUST** migrate to this version (0.7.10).

  It includes a Rake task that prepare the migration to 1.0, so **don't miss that step!**

### 0.7.9 - 2014-12-29

* Fix [#218](https://github.com/jbox-web/redmine_git_hosting/issues/218) (I18n warnings)
* Fix [#288](https://github.com/jbox-web/redmine_git_hosting/issues/288) (wrong deployment key identifier attribution that may lead to a security issue)
* Fix [#317](https://github.com/jbox-web/redmine_git_hosting/issues/317) (inconsistent url's of hierarchical repositories in sub-projects)
* gitolite-admin is a forbiden repository identifier
* Fix ActiveRecord translations
* Better handling of errors on git commit
* Add Rake task to prepare migration to V1.0

### 0.7.8 - 2014-11-08

* Fix collision in method name with Redmine Jenkins Plugin
* Backport patch from [pull #266](https://github.com/jbox-web/redmine_git_hosting/pull/266)
* Fix [#246](https://github.com/jbox-web/redmine_git_hosting/issues/246) (init.rb - config values not taken)
* Fix [#258](https://github.com/jbox-web/redmine_git_hosting/issues/258) (wrong hook installation place on gitolite 3.x)
* Fix [#289](https://github.com/jbox-web/redmine_git_hosting/issues/289) (url to wiki goes nowhere)

**Notes :**

  **Important !**

As explained in [Gitolite documentation](https://gitolite.com/gitolite/non-core.html#localcode) hooks should be installed in a separate directory.
This new version fixes Gitolite hooks install path for Gitolite v3.

Hooks are now stored by default in ```<gitolite user home dir>/local```. You can override this in the plugin settings.

Note that the directory must be **a relative path** to the Gitolite user home directory.

You'll also have to update your ```.gitolite.rc``` accordingly :

    LOCAL_CODE  =>  "$ENV{HOME}/local"

### 0.7.7 - 2014-09-10

* Merge [#259](https://github.com/jbox-web/redmine_git_hosting/pull/259) (Some (very old) repositories have been indentified as empty)
* Merge [#223](https://github.com/jbox-web/redmine_git_hosting/pull/223) (Fix https:// notifications if TLSvX is mandatory #223)
* Bump to jbox-gitolite 1.2.6 which depends on [gitlab-grit 2.7.1](https://github.com/gitlabhq/grit/blob/master/History.txt)

**Notes :**

Until this version, the plugin silently failed when pushing data to Gitolite Admin. Now when an error happens on push, you should get this in the log :

```sh
2014-09-10 19:02:25 +0200 INFO [GitHosting] User 'admin' created a new repository 'test/blof'
2014-09-10 19:02:25 +0200 INFO [GitWorker] Using Gitolite configuration file : 'gitolite.conf'
2014-09-10 19:02:26 +0200 INFO [GitWorker] add_repository : repository 'test/blof' does not exist in Gitolite, create it ...
2014-09-10 19:02:26 +0200 INFO [GitWorker] add_repository : commiting to Gitolite...
2014-09-10 19:02:26 +0200 INFO [GitWorker] add_repository : let Gitolite create empty repository 'repositories/test/blof.git'
2014-09-10 19:02:26 +0200 INFO [GitWorker] add_repository : pushing to Gitolite...
2014-09-10 19:02:26 +0200 ERROR [GitWorker] Command failed [1]: /usr/bin/git --git-dir=/tmp/redmine_git_hosting/git/gitolite-admin.git/.git --work-tree=/tmp/redmine_git_hosting/git/gitolite-admin.git push origin master
[GitWorker]
[GitWorker]To ssh://git@localhost:22/gitolite-admin.git
[GitWorker] ! [rejected]        master -> master (fetch first)
[GitWorker]error: failed to push some refs to 'ssh://git@localhost:22/gitolite-admin.git'
[GitWorker]hint: Updates were rejected because the remote contains work that you do
[GitWorker]hint: not have locally. This is usually caused by another repository pushing
[GitWorker]hint: to the same ref. You may want to first integrate the remote changes
[GitWorker]hint: (e.g., 'git pull ...') before pushing again.
[GitWorker]hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[GitWorker]
```

### 0.7.6 - 2014-07-17

* Bump to jbox-gitolite 1.2.3 which depends on [gitlab-grit 2.7.0](https://github.com/gitlabhq/grit/blob/master/History.txt)
* Fix [#207](https://github.com/jbox-web/redmine_git_hosting/issues/207) (gitolite-admin does not sync anymore) and his brothers

### 0.7.5 - 2014-07-14

* Fix [#226](https://github.com/jbox-web/redmine_git_hosting/issues/226) (unable to download revision if branch has a '/' in the name)
* Fix [#230](https://github.com/jbox-web/redmine_git_hosting/issues/230) (Unwanted access to gitolite-admin repository)

### 0.7.4 - 2014-07-04

* Fix [#184](https://github.com/jbox-web/redmine_git_hosting/issues/184 ) (truncated Bootstrap Switches)
* Fix [#211](https://github.com/jbox-web/redmine_git_hosting/issues/211) (mixed up dates in contributors statistics graph)
* Fix [#215](https://github.com/jbox-web/redmine_git_hosting/issues/215) (application.css conflicts)
* Fix [#225](https://github.com/jbox-web/redmine_git_hosting/issues/225) (unable to set new repository deployment credentials)
* Set extra_info field when auto-creating repo with project

### 0.7.3 - 2014-06-11

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

### 0.7.2 - 2014-04-16

* Fix [#160](https://github.com/jbox-web/redmine_git_hosting/issues/160)
* Fix [#169](https://github.com/jbox-web/redmine_git_hosting/issues/169)

### 0.7.1 - 2014-04-14

* Remove ENV['HOME'] dependency
* Remove Git config file dependency
* Remove SSH config file dependency
* Fix log redirection on Automatic Repository Initialization
* Fix plugin portability (use env instead of export)
* Fix layout bug in header navigation ([#162](https://github.com/jbox-web/redmine_git_hosting/pull/162)) (thanks soeren-helbig)
* Fix projects update on locking/unlocking user
* Various small fixes
* Use last version of [jbox-gitolite](http://rubygems.org/gems/jbox-gitolite) gem (1.1.11)

### 0.7.0 - 2014-04-02

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

### 0.6.3 - 2014-02-23

This is a bugfix release.

This is the last release of the 0.6.x branch.

The 'v0.6' is kept as archive and will be no longer supported.

### 0.6.2 - 2013-07-29

This is a security and bugfix release.

This releases fixes a high risk vulnerability, allowing an attacker to gain shell access to the server (CVE-2013-4663).

We strongly advise you to update your plugin!

### 0.6.1 - 2013-04-05

This is a bugfix release.

### 0.6.0 - 2013-03-25

This is a compatibility release.

The plugin is now compatible with Redmine 2.x (and Redmine 1.x).

### 0.5.2 - 2012-12-25

This is a bug-fix release.

* Fixed a migration problem with PostGreSQL (for uninstalling).
* Fix to allow validations to fail properly on Project creation for Redmine < 1.4
* Fix to prevent repository creation from stealing preexisting repositories in gitolite (which could happen under specialized circumstances).
* Fix to handle old versions of sudo (< 1.7.3) during repair of the administrative key
* Fix to preserve other administrative keys in the gitolite configuration file.  Previously, the plugin would delete all but the first one.  This fix is useful for people who want to have separate administrative keys for access to the gitolite config file.
* Fixed weird behavior on Repository page when using multiple repos/project.  Showed up when on non-default repo when trying to switch to branch other than master.  Would switch back to default repository.

### 0.5.1 - 2012-10-31

This is a bug-fix release.

* Post-Receive URLs should now work with SSL (i.e. URLs of the form "https://xxx")
* Additional patches for backward compatibility with ChiliProject/Redmine < 1.4. In this category was a problem with editing Git repo parameters as well as a minor bug that caused problems with adding members to projects that didn't have a Git repo.
* Additional patches to support Ruby 1.9.x.  Includes fix to post-receive hook and change in meaning of Module#instance_methods.
* Patched installation so that can install Redmine from *scratch* (i.e. run `rake db:migrate` on empty DB) with plugin already in place.
* Latest migration should now work with PostGreSQL.  This was broken in 0.5.0x.

### 0.5.0 - 2012-10-03

This is a feature release.

* New : Compatibility with Redmine 1.4
* Fix : Uninstall of plugin should work properly now.
* Fix : Problems with patching on some installations should be fixed now (introduced in a recent revision).

### 0.4.6 - 2012-08-22

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

### 0.4.5 - 2012-04-23

* Fixed missed case for compatibility with Redmine 1.1-Stable.  This patch allows the mirror functionality to work.
* Fixed bad interaction between cron cleanup of /tmp and access to gitolite-admin repository in /tmp.  Behavior could cause user keys to appear to be deleted, even though they remain in the redmine database.  This behavior has likely been a part of this plugin since before this branch was forked (pre 0.4.2).

### 0.4.4 - 2012-04-01

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

### 0.4.3 - 2012-02-01

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

### 0.4.2 - 2011-12-01

This release includes feature enhancements and bug fixes.

* One of the most important aspects of this release is a fix for the performance problems that plagued earlier versions of the plugin for post 1.2 Redmine. Fetch_changesets operations should now be possible.
* A second aspect is support for selinux.  Scripts have been placed into a separate /bin directory which is placed at the root of the plugin (i.e. REDMINE_ROOT/vendor/plugins/redmine_git_hosting/bin).  A set of rake tasks have been added to assist in installing selinux tags and pre-building scripts in the bin directory.
