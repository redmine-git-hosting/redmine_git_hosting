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

***

#### Placement and modification of executable scripts

<div class="alert alert-warning" role="alert">This only apply for Redmine Git Hosting version <strong>< 0.8</strong></div>

You may place the executable scripts anywhere in the filesystem.  The default location of the scripts is set with **:gitolite_script_dir**.

The default values :

    REDMINE_ROOT/plugins/redmine_git_hosting/bin         # Redmine 2.x
    REDMINE_ROOT/vendor/plugins/redmine_git_hosting/bin  # Redmine 1.x

are a good location, especially if you have multiple simultaneous Redmine installations on the same host, since scripts are customized to each installation.

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
