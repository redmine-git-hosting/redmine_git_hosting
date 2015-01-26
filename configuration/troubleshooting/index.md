---
layout: default
title: Troubleshooting
---

### {{ page.title }}
***

#### A note about PATH variable

One major source of issues with this plugin is that Redmine needs to be able to run both sudo and git commands. Specifically, these programs need to be in one of the directories specified by the PATH variable, in your Rails environment. This requirement has been known to cause problems, particularly when installing on FreeBSD.

To address this problem in the Apache + Passenger configuration, one possible solution is to do the following :

**(1)** Create a new file ```/usr/local/bin/ruby18env``` with the following code, modifying the PATH shown below to include all relevant directories :

    #!/bin/sh
    export PATH="/usr/local/lib/ruby/gems/1.8/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
    [path_to_your_ruby_executable, e.g. /usr/local/bin/ruby18] $*

**(2)** Make this file executable:

    chmod 755 /usr/local/bin/ruby18env

**(3)** In your httpd.conf file, replace (or add) your PassengerRuby directive with:

    PassengerRuby /usr/local/bin/ruby18env

Note that this may be an issue for configurations other than Apache + Passenger, but as this is one of the most common configurations, instructions for that are provided above.

Thanks to user Tronix117 for helping to track down this issue and provide a solution for Apache + Passenger.

***

#### A note about HOME variable

The HOME variable must be properly set in the execution environment.

It seems that it's not the case for Nginx + Thin.

To address this problem one possible solution is to do the following :

Edit the ```/etc/init.d/thin``` file and change the line

    /usr/bin/ruby1.9.1 $DAEMON $ACTION --all /etc/thin1.9.1

to

    export HOME=/home/redmine && /usr/bin/ruby1.9.1 $DAEMON $ACTION --all /etc/thin1.9.1

Thanks to user overmind88 for providing a solution for Nginx + Thin.

***

#### Hook errors while pushing over HTTPS

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

***

#### Error : no suitable markdown gem found

If you installed Redmine with the Debian package, a dependency is missing :

    root$ apt-get install ruby-redcarpet

***

#### Initialization of the repo with README file does not work

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

***

#### My repository seems empty but I'm sure it is not!

> A ```git clone``` of the repository gives me files!

    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ bundle exec rake redmine_git_hosting:fetch_changesets RAILS_ENV=production


<div id="toc">
</div>
