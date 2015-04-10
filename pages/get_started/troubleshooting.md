---
title: Troubleshooting
permalink: /troubleshooting/
---

#### Hook errors while pushing over HTTPS
***

    user$ git push origin master
    Password for 'https://xxx@xxx':
    Counting objects: 743, done.
    Delta compression using up to 2 threads.
    Compressing objects: 100% (536/536), done.
    Writing objects: 100% (743/743), 8.98 MiB | 9.18 MiB/s, done.
    Total 743 (delta 298), reused 0 (delta 0)
    remote: Empty compile time value given to use lib at hooks/update line 6
    remote: Use of uninitialized value in require at hooks/update line 7.
    remote: Can't locate Gitolite/Hooks/Update.pm in @INC (@INC contains:  /etc/perl /usr/local/lib/perl/5.14.2 /usr/local/share/perl/5.14.2 /usr/lib/perl5 /usr/share/perl5 /usr/lib/perl/5.14 /usr/share/perl/5.14 /usr/local/lib/site_perl .) at hooks/update line 7.
    remote: BEGIN failed--compilation aborted at hooks/update line 7.
    remote: error: hook declined to update refs/heads/master
    To https://xxx@xxx/redmine/xxx.git
     ! [remote rejected] master -> master (hook declined)
    error: failed to push some refs to 'https://xxx@xxx/redmine/xxx.git'

This is a known issue with Gitolite 3 and SmartHTTP access ([https://github.com/gitlabhq/gitlabhq/issues/1495](https://github.com/gitlabhq/gitlabhq/issues/1495)).

The trick is to add the following code at the bottom of the files :

* ```/<git user home dir>/bin/lib/Gitolite/Hooks/Update.pm```
* ```/<git user home dir>/gitolite/src/lib/Gitolite/Hooks/Update.pm```
* ```/<git user home dir>/.gitolite/hooks/common/update```

```
__DATA__
#!/usr/bin/perl

BEGIN {
  exit 0 if exists $ENV{GL_BYPASS_UPDATE_HOOK};
}

use strict;
use warnings;
...
```

You must do this every time you update Gitolite.

#### Error : no suitable markdown gem found
***

If you installed Redmine with the Debian package, a dependency is missing :

    root$ apt-get install ruby-redcarpet

#### Initialization of the repo with README file does not work
***

To make it work you must allow Redmine Admin key to write on every repo :

First declare the Gitolite Admin SSH key in ```.ssh/config``` to easily clone/push :

    root$ su - redmine
    redmine$ vi .ssh/config
    * [add this]
    Host localhost
      User git
      IdentityFile /home/redmine/redmine/plugins/redmine_git_hosting/ssh_keys/redmine_gitolite_admin_id_rsa
      IdentitiesOnly yes

Then clone Gitolite Admin repository :

    redmine$ git clone ssh://git@localhost:<PORT>/gitolite-admin.git /tmp/gitolite-admin-temp

Then edit ```gitolite.conf``` file to add this :

    redmine$ cd /tmp/gitolite-admin-temp
    redmine$ vi conf/gitolite.conf
    * [add this]
    repo    @all
      RW+                            = redmine_gitolite_admin_id_rsa

Finally commit and push :

    redmine$ git commit -a -m 'Allow Redmine Key to access all repositories'
    redmine$ git push -u origin master

You can now remove the temp dir and the SSH config file

    redmine$ rm -rf /tmp/gitolite-admin-temp
    redmine$ rm .ssh/config

#### My repository seems empty but I'm sure it is not!
***

> A ```git clone``` of the repository gives me files!

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ bundle exec rake redmine_git_hosting:fetch_changesets RAILS_ENV=production

#### Bundle and Bitnami Stack
***

If ```bundle``` command complains here what to do :

    bitnami$ cd /opt/bitnami/apps/redmine/htdocs/vendor
    bitnami$ rm -rf bundle
    bitnami$ cd /opt/bitnami/apps/redmine/htdocs
    bitnami$ bundle install --without development test --deployment

#### Temp dir and Bitnami Stack
***

The temp directory must be **fully** accesible for the ```daemon``` user so here what to do :

    bitnami$ cd /opt/bitnami/apps/redmine
    bitnami$ mkdir temp
    bitnami$ sudo chown -R daemon\: temp

Then go in *Administration -> Redmine Git Hosting -> Global tab* and set the temp directory to ```/opt/bitnami/apps/redmine/temp```.
