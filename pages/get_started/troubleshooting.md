---
title: Troubleshooting
permalink: /troubleshooting/
---


#### Error : no suitable markdown gem found
***

If you installed Redmine with the Debian package, a dependency is missing :

    root$ apt-get install ruby-redcarpet


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


#### Unsupported URL protocol
***

If you got this error it means that rugged/libgit2 has not been compiled with SSH support.

Install [missing dependencies](http://redmine-git-hosting.io/get_started/#step-1-install-dependencies) then :

    root# su - redmine

    redmine$ cd REDMINE_ROOT
    redmine$ bundle clean --force
    redmine$ bundle config set --local without 'development:test'
    redmine$ bundle config set --local build.rugged --with-ssh
    redmine$ bundle install
