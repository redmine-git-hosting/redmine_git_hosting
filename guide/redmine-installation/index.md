---
layout: default
title: Redmine installation
---

<div id="toc">
  <h3>Redmine installation</h3>

  <ul>
    <li><strong>(step 1)</strong> <a href="#step-1-create-the-redmine-user">Create the <code>redmine</code> user</a></li>
    <li><strong>(step 2)</strong> <a href="#step-2-install-rvm-ruby-version-manager">Install RVM (Ruby Version Manager)</a></li>
    <li><strong>(step 3)</strong> <a href="#step-3-install-ruby">Install Ruby</a></li>
    <li><strong>(step 4)</strong> <a href="#step-4-install-redmine">Install Redmine</a></li>
    <li><strong>(step 5)</strong> <a href="#step-5-install-and-configure-puma">Install and configure Puma</a></li>
    <li><strong>(step 6)</strong> <a href="#step-6-create-the-puma-start-script">Create the Puma start script :</a></li>
    <li><strong>(step 7)</strong> <a href="#step-7-configure-nginx">Configure Nginx</a></li>
    <li><strong>(step 8)</strong> <a href="#step-8-create-debian-init-script-if-youre-using-debian">Create Debian init script (if you’re using Debian)</a></li>
  </ul>
</div>


You should not use ```www-data``` account to run Redmine. This is a common mistake.
The best way to run Rails apps is to create a separate standard user, lets say ```redmine```, and install Redmine within the user's home. In that case, you should use Nginx and Puma (or other webservers) to serve Redmine.

#### **(step 1)** Create the ```redmine``` user

    root$ adduser --disabled-password redmine


#### **(step 2)** Install RVM (Ruby Version Manager)

    root$ su - redmine
    redmine$ curl -L https://get.rvm.io | bash


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


#### **(step 3)** Install Ruby

    root$ su - redmine
    redmine$ rvm install 2.1.1


#### **(step 4)** Install Redmine

Change current user then follow the Redmine installation tutorial with this user

    root$ su - redmine

http://www.redmine.org/projects/redmine/wiki/RedmineInstall

At the end of the Redmine installation, be sure to have :

    /home/redmine
    /home/redmine/.ssh
    /home/redmine/bin
    /home/redmine/etc
    /home/redmine/redmine ----> /home/redmine/redmine-2.5.2 # Symbolic link
    /home/redmine/redmine-2.5.2
    /home/redmine/redmine-2.5.1

The symbolic link is here to make Redmine upgrades easy.

* The ```bin``` dir will contain the services start script (Puma, Sidekiq ...)
* The ```etc``` dir will contain the services config file
* The ```.ssh``` dir will contain the Gitolite admin key


#### **(step 5)** Install and configure Puma

Install Puma gem :

    root$ su - redmine
    redmine$ gem install puma

Then create the config file [```/home/redmine/etc/puma.rb```](https://github.com/jbox-web/redmine_git_hosting/blob/devel/contrib/scripts/puma.rb)


#### **(step 6)** Create the Puma start script

This goes in [```/home/redmine/bin/server_puma.sh```](https://github.com/jbox-web/redmine_git_hosting/blob/devel/contrib/scripts/server_puma.sh)


#### **(step 7)** Configure Nginx

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


#### **(step 8)** Create Debian init script (if you're using Debian)

This goes in [```/etc/init.d/redmine```](https://github.com/jbox-web/redmine_git_hosting/blob/devel/contrib/scripts/redmine)

This way, you can manage Redmine independantly of Nginx :

    /etc/init.d/redmine start
    /etc/init.d/redmine stop

or

    root$ su - redmine
    redmine$ server_puma.sh start
    redmine$ server_puma.sh stop
