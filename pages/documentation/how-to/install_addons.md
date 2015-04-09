---
title: Addons installation
permalink: /how-to/install-addons/
---

#### Serve Git repositories with Apache
***

**1)** Install dependencies :

    root# apt-get install libapache-dbi-perl libapache2-mod-perl2 libdbd-mysql-perl
    root# apt-get install libauthen-simple-ldap-perl libio-socket-ssl-perl

    # Then

    root# mkdir /usr/lib/perl5/Apache/Authn
    root# cp <redmine_root_dir>/extra/svn/Redmine.pm /usr/lib/perl5/Apache/Authn/Redmine.pm
    root# a2enmod cgi

**2)** Then create a virtual host file :

    <VirtualHost *:80>

      ServerName git.example.com

      PerlLoadModule Apache::Authn::Redmine

      SetEnv GIT_PROJECT_ROOT /data/git/repositories/
      SetEnv GIT_HTTP_EXPORT_ALL

      ScriptAlias / /usr/lib/git-core/git-http-backend/

      <Directory "/usr/lib/git-core/">
        AllowOverride None
        Options +ExecCGI -Includes
        Order allow,deny
        Allow from all
      </Directory>

      <Location />
        Order allow,deny
        Allow from all

        AuthType Basic
        AuthName "Git Repositories"
        AuthUserFile /dev/null
        Require valid-user

        PerlAccessHandler Apache::Authn::Redmine::access_handler
        PerlAuthenHandler Apache::Authn::Redmine::authen_handler

        RedmineDSN "DBI:mysql:database=db_name;host=127.0.0.1"
        RedmineDbUser "db_user"
        RedmineDbPass "db_pass"
        RedmineGitSmartHttp yes
      </Location>

      # Possible values include: debug, info, notice, warn, error, crit,
      # alert, emerg.
      LogLevel warn
      CustomLog /var/log/apache2/gitolite.access.log combined
      ErrorLog  /var/log/apache2/gitolite.error.log

    </VirtualHost>

**3)** Your Gitolite repositories must have at least 750 permissions, if not :

    root# su - git
    ## This can take some time
    git$ find repositories/ -type f -exec chmod 640 {} \;
    git$ find repositories/ -type d -exec chmod 750 {} \;

Then add ```www-data``` to ```git``` group

    root# usermod -a -G git www-data

**4)** Then restart Apache :

    root# /etc/init.d/apache2 restart

To keep 750 permissions for new repositories, edit ```UMASK``` setting in ```.gitolite.rc``` file :

    root# su - git
    git$ vi .gitolite.rc
    ## Set UMASK
    UMASK                           =>  0027,
    ## ESC, :x

That's all!

#### Use Redmine to store Git Annex repositories
***

**1)** Install ```git-annex``` on the Redmine server :

    ## On Debian Wheezy (with backports)
    root# apt-get -t wheezy-backports install git-annex

For others distributions please refer to [http://git-annex.branchable.com/install/](http://git-annex.branchable.com/install/).


**2)** Edit ```~/.gitolite.rc``` to enable the git-annex-shell command. Find the ```ENABLE``` list and add this line in there somewhere :

    'git-annex-shell ua',


**3)** Create a repo within Redmine

{{ site.data.callouts.alertwarning }}
  Be sure to be a project member with **commit** permission.
{{ site.data.callouts.end }}

**4)** Install ```git-annex``` on your desktop (here's ArchLinux) and follow the [walkthrough](http://git-annex.branchable.com/walkthrough/), basically :

    nicolas$ mkdir ~/annex
    nicolas$ cd ~/annex
    nicolas$ git init
    nicolas$ git annex init "my desktop"
    nicolas$ git remote add origin ssh://git@redmine.example.org/test.git ## The one created in Redmine
    nicolas$ touch toto
    nicolas$ git annex add .
    nicolas$ git commit -a -m test
    nicolas$ git annex sync
