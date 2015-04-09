---
title: Supported features
permalink: /supported_features/
excerpt: Before you get into exploring Jekyll as a potential platform for help content, you may be wondering if it supports some basic features. The following table shows what is supported in Jekyll.
---

Features | Supported | Notes
---------|-----------|------
SSH Public Keys Management          | {{ site.data.callouts.icon_ok }} | Allow Redmine users to manage their own SSH keys.
Automatic Repository Creation       | {{ site.data.callouts.icon_ok }} | You can automatically create a new Git repository every time you create a new project. You won't have to create the project and then create the repository, this will be done all it one step.
Automatic Repository Initialization | {{ site.data.callouts.icon_ok }} | You can automatically initialize a new Git repository with a README file (à la Github).
Repository Deletion                 | {{ site.data.callouts.icon_ok }} | This plugin can handle repositories deletion by puting them in a Recycle Bin for a configurable amount of time.
Deployment Credentials              | {{ site.data.callouts.icon_ok }} | This plugin provides deployment credentials on a per-repository basis. One typical use-case would be for all deploy keys to be owned by the administrator and attached selectively to various repositories.
Post-Receive URLs                   | {{ site.data.callouts.icon_ok }} | This plugin supports the inclusion of GitHub-style Post-Receive URLs. Once added, a post-receive URL will be notified when new changes are pushed to the repository.
Automatic Mirror Updates            | {{ site.data.callouts.icon_ok }} | This plugin can automatically push updates to repository mirrors when new changes are pushed to the repository.
Git SmartHTTP                       | {{ site.data.callouts.icon_ok }} | This plugin allows you to automatically enable Git SmartHTTP access to your repositories.
Git Daemon                          | {{ site.data.callouts.icon_ok }} | This plugin allows you to manage repositories exported via GitDaemon.
Caching Options                     | {{ site.data.callouts.icon_ok }} | When browsing a repository within Redmine interface the plugin caches the output of Git commands to dramatically improve page load times, roughly a 10x speed increase.
Git mailing lists                   | {{ site.data.callouts.icon_ok }} | This plugin embeds [git-multimail hook](https://github.com/mhagger/git-multimail) to send notification emails for pushes to a Git repository.
Sidekiq asynchronous jobs           | {{ site.data.callouts.icon_ok }} | Speedup repositories creation by executing tasks in background.
Default branch selection            | {{ site.data.callouts.icon_ok }} | By default, the repository default branch is called ```master```. If you have admin rights over a repository, you can change the default branch on the repository.
Git Revision Download               | {{ site.data.callouts.icon_ok }} | This feature adds a download link to the Git repository browser, allowing users to download a snapshot at a given revision.
README Preview                      | {{ site.data.callouts.icon_ok }} | This feature allows to display the content of README file at repository tab.
Git Config Keys Management          | {{ site.data.callouts.icon_ok }} | You can manage Git config key/value pairs for each repository.
Improved Repository Statistics      | {{ site.data.callouts.icon_ok }} | Use Highcharts library to display nice graphs.
Github Issues Sync                  | {{ site.data.callouts.icon_ok }} | Keep your Github issues synchronized with Redmine !!
Browse Archived Repositories        | {{ site.data.callouts.icon_ok }} | If you are Admin in Redmine you can browse archived repositories by clicking on *Archived repositories* in the top menu.
