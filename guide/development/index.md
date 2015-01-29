---
layout: default
title: Development Guide
---

### {{ page.title }}
***

#### Introduction

<div class="alert alert-danger" role="alert">Do this in a test environment ! I won't be responsible if you break things on your production installation !</div>

*You can use a Virtual Machine to clone your production environment then play the migration.*

This is my current configuration :

    Environment:
      Redmine version                2.6.1.stable
      Ruby version                   2.1.5-p273 (2014-11-13) [x86_64-linux]
      Rails version                  3.2.21
      Environment                    development
      Database adapter               Mysql2
    SCM:
      Subversion                     1.6.17
      Mercurial                      2.2.2
      Git                            1.7.10.4
      Filesystem
      Xitolite                       1.7.10.4
    Redmine plugins:
      redmine_bootstrap_kit          0.2.0
      redmine_git_hosting            1.0-devel
      redmine_sidekiq                2.1.0

    Sudo version is 1.8.5p2 (but I don't think we should care of it now)
    Debian Wheezy 7.8
    Gitolite v3.6.2-12-g1c61d57

***

#### To install the devel branch

Follow the [installation guide]({{ site.baseurl }}/howtos/install/) and when it comes to git checkout the branch for Redmine Git Hosting checkout the ```devel``` branch.

Then install development gems with :

    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without nothing

***

#### Play RSpec tests

    ## Copy the RSpec helper :
    root$ su - redmine
    redmine$ cd REDMINE_ROOT
    redmine$ mkdir spec
    redmine$ cp plugins/redmine_git_hosting/spec/root_spec_helper.rb spec/spec_helper.rb

    ## And watch the tests passing :)
    redmine$ rspec plugins/redmine_git_hosting/spec/

<div id="toc">
</div>
