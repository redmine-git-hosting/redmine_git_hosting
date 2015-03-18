---
layout: default
title: Redmine installation
---

### {{ page.title }}
***

#### Why?
***

You should not use ```www-data``` account to run Redmine. This is (I think) a mistake and you may have troubles with file permissions on certain files. (Private SSH keys for instance, that should be accessible for only one user and certainly not the ```www-data``` user)

The best way to run Redmine and (Rails apps in general) is to create a separate standard user, lets say ```redmine```, and install Redmine within the user's home. In that case, you should use Nginx and Puma (or other webservers) to serve Redmine.

Nginx will run with ```www-data``` user but will communicate with Redmine via a UNIX socket and thus avoiding troubles with file permissions.

Requests will be send to and executed by Puma which runs with the ```redmine``` user and has the needed permissions on sensitive files.

Often 600 on SSH private keys what you **can't** do if you serve Redmine with Apache (at least 640 by using groups or worse 644).

Also it will permit you to keep your Redmine updated as it won't depend on system librairies which bring the 'Wrong dependency version' issue.

So this tutorial :)

<br/>

#### **(step 1)** Create the ```redmine``` user

    root# adduser --disabled-password redmine

***

#### **(step 2)** Install RVM

[Ruby Version Manager](https://rvm.io/) (RVM) is a command-line tool which allows you to easily install, manage, and work with multiple ruby environments from interpreters to sets of gems.

    root# su - redmine
    redmine$ gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    redmine$ curl -sSL https://get.rvm.io | bash -s stable


Be sure to have this in ```/home/redmine/.profile``` :

    # Set PATH so it includes user's private bin if it exists
    if [ -d "$HOME/bin" ] ; then
      PATH="$HOME/bin:$PATH"
    fi

    # set PATH so it includes rvm bin if it exists
    if [ -d "$HOME/.rvm/bin" ] ; then
      PATH="$PATH:$HOME/.rvm/bin"
    fi

    if [ -s "$HOME/.rvm/scripts/rvm" ] ; then
      source "$HOME/.rvm/scripts/rvm"
    fi

    if [ -s "$HOME/.rvm/scripts/completion" ] ; then
      source "$HOME/.rvm/scripts/completion"
    fi

Now you should logout from Redmine user with ```exit``` then 'relogin' with ```su - redmine``` to reload env vars properly.

***

#### **(step 3)** Install Ruby

    redmine$ rvm install 2.1.4

***

#### **(step 4)** Install Redmine

Change current user then follow the [Redmine installation tutorial](http://www.redmine.org/projects/redmine/wiki/RedmineInstall) with this user :

    root# su - redmine


At the end of the Redmine installation, be sure to have :

    /home/redmine
    /home/redmine/bin
    /home/redmine/etc
    /home/redmine/redmine ----> /home/redmine/redmine-2.6.1 # Symbolic link
    /home/redmine/redmine-2.6.1
    /home/redmine/redmine-2.5.2
    /home/redmine/redmine-2.5.1
    /home/redmine/ssh_keys

The symbolic link is here to make Redmine upgrades easy.

* The ```bin``` dir will contain the services start script (Puma, Sidekiq ...)
* The ```etc``` dir will contain the services config file
* The ```ssh_keys``` dir will contain the Gitolite admin key

***

#### **(step 5)** Install Puma

Install Puma gem :

    redmine$ gem install puma

Create the Puma config file ```/home/redmine/etc/puma.rb``` with this [content](https://github.com/jbox-web/redmine_git_hosting/blob/devel/contrib/scripts/puma.rb).

Then create the Puma start script ```/home/redmine/bin/server_puma.sh``` with this [content](https://github.com/jbox-web/redmine_git_hosting/blob/devel/contrib/scripts/server_puma.sh) and make it executable :

    redmine$ chmod +x /home/redmine/bin/server_puma.sh

***

#### **(step 6)** Configure Nginx

This is a sample conf for Nginx :

    upstream puma_redmine {
      server        unix:/home/redmine/redmine/tmp/sockets/redmine.sock fail_timeout=0;
      #server        127.0.0.1:3000; #dev mode
    }

    server {
      server_name   redmine.example.com
      listen        0.0.0.0:80;
      root          /home/redmine/redmine;

      access_log    /var/log/nginx/redmine.log;
      error_log     /var/log/nginx/redmine.log;

      location / {
        try_files $uri @ruby;
      }

      location @ruby {
        #proxy_set_header X-Forwarded-Proto https; # unquote if you are in HTTPs
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_read_timeout 300;
        proxy_pass http://puma_redmine;
      }
    }

***

#### **(step 7)** Create Debian init script

If you're using Debian you can create the file ```/etc/init.d/redmine``` with this [content](https://github.com/jbox-web/redmine_git_hosting/blob/devel/contrib/scripts/redmine).

This way, you can manage Redmine independantly of Nginx :

    /etc/init.d/redmine start
    /etc/init.d/redmine stop

or

    root# su - redmine
    redmine$ server_puma.sh start
    redmine$ server_puma.sh stop


<div id="toc">
</div>
