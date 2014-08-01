---
layout: default
title: Development Guide
---

### {{ page.title }}
***

#### Introduction

<div class="alert alert-danger" role="alert">Do this in a test environment ! I won't be responsible if you break things on your production installation !</div>

*You can use a Virtual Machine to clone your production environment then play the migration.*

But don't afraid, the plugin is very stable and at least I can say that it works for me in an awesome way :)

This is my current configuration :

    Environment:
      Redmine version                2.5.2.stable
      Ruby version                   2.0.0-p451 (2014-02-24) [x86_64-linux]
      Rails version                  3.2.19
      Environment                    development
      Database adapter               Mysql2
    SCM:
      Subversion                     1.6.17
      Mercurial                      2.2.2
      Git                            1.9.1
      Filesystem
    Redmine plugins:
      redmine_bootstrap_kit          0.1
      redmine_git_hosting            0.8-devel
      redmine_sidekiq                2.1.0

    Sudo version is 1.8.5p2 (but I don't think we should care of it now)
    Debian Wheezy 7.6
    Gitolite v3.5.3.1-11-g8f1fd84


***

#### To install the devel branch

The devel branch (and the future 0.8 version) now depends on [gitolite-rugged](https://github.com/oliverguenther/gitolite-rugged) and no more on [jbox-gitolite](https://github.com/jbox-web/gitolite).

The main difference is that ```gitolite-rugged``` uses [libgit2/rugged](https://github.com/libgit2/rugged) whereas ```jbox-gitolite``` uses [gitlab-grit](https://github.com/gitlabhq/grit) to handle the Gitolite Admin repository.

**About Gitlab Grit :**

> Grit gives you object oriented read/write access to Git repositories via Ruby. To this end, some of the interactions with Git repositories are done by shelling out to the system's git command, and other interactions are done with pure Ruby reimplementations of core Git functionality

**About libgit2/rugged:**

> libgit2 is a pure C implementation of the Git core methods.

> Rugged is a library for accessing libgit2 in Ruby. It gives you the speed and portability of libgit2 with the beauty of the Ruby language.

So between the 2 Gitolite libs, no more need to ```exec()``` git commands :)

libgit2 is bundled with gitolite-rugged so you don't have to install it at the system level. But you have to install it's dependencies :

    root$ apt-get install libssh2-1 libssh2-1-dev cmake libgpg-error-dev

Then you can install the plugin :

    root$ su - redmine
    redmine$ cd REDMINE_ROOT/plugins
    redmine$ git clone https://github.com/ogom/redmine_sidekiq.git
    redmine$ git clone https://github.com/jbox-web/redmine_bootstrap_kit.git
    redmine$ git clone https://github.com/jbox-web/redmine_git_hosting.git
    redmine$ cd redmine_git_hosting/
    redmine$ git checkout devel
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without nothing

    ## IMPORTANT !
    ## Do this before any Rails migration !
    ## Some migration files has been renumbered (missing digit)
    redmine$ RAILS_ENV=production rake redmine_git_hosting:fix_migration_numbers

    ## Then do last migrations
    redmine$ RAILS_ENV=production NAME=redmine_git_hosting rake redmine:plugins:migrate

    ## Then reset SSH keys identifier (yes, again)
    redmine$ RAILS_ENV=production rake redmine_git_hosting:rename_ssh_keys


***

#### Play RSpec tests

    ## Copy the RSpec helper :
    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ mkdir spec
    redmine$ cp plugins/redmine_git_hosting/spec/root_spec_helper.rb spec/spec_helper.rb

    ## Install and start Zeus
    redmine$ gem install zeus
    redmine$ zeus start

    ## Then in an other console :
    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ zeus rspec plugins/redmine_git_hosting/spec/

    ## And watch the tests passing :)

    ## To generate SimpleCov reports (or to test without installing Zeus) :
    redmine$ rspec plugins/redmine_git_hosting/spec/

<div id="toc">
</div>
