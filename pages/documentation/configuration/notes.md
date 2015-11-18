---
title: Configuration notes
permalink: /configuration/notes/
---


#### Repositories Storage Configuration Strategy
***

Redmine Git Hosting has 2 modes to store repositories in Gitolite :

* **hierarchical** : repositories will be stored in Gitolite into a hierarchy that mirrors the project hierarchy.

* **flat** : repositories will be stored in Gitolite directly under ```repository/```, regardless of the number and identity of any parents that they may have.


#### Interaction with non-Redmine Gitolite users
***

This plugin respects Gitolite repositories that are managed outside of Redmine or managed by both Redmine and non-Redmine users :

* Users other than **redmine_*** are left untouched and can be in projects by themselves or mixed in with projects managed by redmine.

* When a Redmine-managed project is deleted (with the **Delete Git Repository When Project Is Deleted** option enabled), its corresponding Git repository **will not be deleted/recycled** if there are non-Redmine users in the *gitolite.conf* file.


#### A note about the ```PATH``` variable
***

One major source of issues with this plugin is that Rails needs to be able to run both ```sudo``` and ```git``` commands.  Specifically, these programs need to be in one of the directories specified by the ```PATH``` variable, in your Rails environment. This requirement has been known to cause problems.

* With Passenger

When working as Nginx extension, Passenger creates a sandbox so environment variables aren't sent to Passenger.
To fix this you must add this to your Nginx configuration (server section) :

```
passenger_env_var PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin;
```

#### A note about ```HOME``` variable
***

The ```HOME``` variable must be properly set in the execution environment. It seems that it's not the case for Nginx + Thin.
To address this problem one possible solution is to do the following :

Edit the ```/etc/init.d/thin``` file and change the line

    /usr/bin/ruby1.9.1 $DAEMON $ACTION --all /etc/thin1.9.1

to

    export HOME=/home/redmine && /usr/bin/ruby1.9.1 $DAEMON $ACTION --all /etc/thin1.9.1

Thanks to user overmind88 for providing a solution for Nginx + Thin.
