---
layout: default
title: Addons installation
---

### {{ page.title }}
***

#### Serve Git repositories with Apache

In console :

    ## Sorry ruby users but you need some perl modules, at least mod_perl2,
    ## DBI and DBD::mysql (or the DBD driver for you database as it should
    ## work on allmost all databases).

    root$ apt-get install libapache-dbi-perl libapache2-mod-perl2 libdbd-mysql-perl

    ## If your Redmine users use LDAP authentication, you will also need
    ## Authen::Simple::LDAP (and IO::Socket::SSL if LDAPS is used):

    root$ apt-get install libauthen-simple-ldap-perl libio-socket-ssl-perl

    ## Then

    root$ mkdir /usr/lib/perl5/Apache/Authn
    root$ cp <redmine_root_dir>/extra/svn/Redmine.pm /usr/lib/perl5/Apache/Authn/Redmine.pm
    root$ a2enmod cgi

Then create a virtual host file :

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

Your Gitolite repositories must have at least 750 permissions, if not :

    root$ su - git
    ## This can take some time
    git$ find repositories/ -type f -exec chmod 640 {} \;
    git$ find repositories/ -type d -exec chmod 750 {} \;

Then add ```www-data``` to ```git``` group

    root$ usermod -a -G git www-data

Then restart Apache :

    root$ /etc/init.d/apache2 restart

To keep 750 permissions for new repositories, edit ```UMASK``` setting in ```.gitolite.rc``` file :

    root$ su - git
    git$ vi .gitolite.rc
    ## Set UMASK
    UMASK                           =>  0027,
    ## ESC, :x

That's all!
