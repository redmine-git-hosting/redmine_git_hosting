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

I need testers for testing this version and specially the migration from 0.7.x. If you're interested ```git clone``` the devel branch and test it ! :)

I wrote a [development guide]({{ site.baseurl }}/guide/development/) if you're interested on working/testing the plugin.

***

{% for post in site.categories['release-notes'] %}
  {{ post.excerpt }}
{% endfor %}
