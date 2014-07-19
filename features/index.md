---
layout: default
title: Features
group: navigation
weight: 3
---

<div id="toc">
</div>


### Features
***

#### SSH Public Keys Management

Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

***

#### Automatic Repository Creation

With this option enabled you can automatically create a new Git repository every time you create a new project. You won't have to create the project and then create the repository, this will be done all it one step.

***

#### Automatic Repository Initialization

With this option enabled you can automatically initialize a new Git repository with a README file (à la Github).

***

#### Repository Deletion

This plugin can handle repositories deletion by puting them in a Recycle Bin for a configurable amount of time (defaulting to 24 hours). It can also handle repositories recovery.

Pleaser refer to [Configuration variables]({{ site.baseurl }}/configuration/variables/#redmine-config) for Repository Deletion configuration.

***

#### Deployment Credentials

This plugin provides deployment credentials on a per-repository basis. These credentials are combinations of a public key and access permissions (R or RW+) which are attached directly to a repository rather than by attaching users to repositories. Deployment credentials may be added to a repository through the repository settings interface. They may be added by anyone who is a manager for the project or by the administrator.

Public keys used in this way are called "deploy keys". They are owned by the user who created them and may be edited on the user's public_key page (which is under "my account" for individual users). Since keys have unique names (per creator), they may be reused in multiple deployment credentials (in multiple repositories), simply by selecting them from the pulldown menu on the "deployment credentials create" dialog box.

One typical use-case would be for all deploy keys to be owned by the administrator and attached selectively to various repositories. Note that the "deployment credentials create" dialog is actually a convenience dialog in that it allows the simultaneous creation of both a deploy key and deployment credential in a single step, even suggesting a name for the deployment credential, with the eye to deployments that have a separate deploy key for each repository. Reusing a deploy key in another credential is a simple matter of selecting the key from a drop-down menu.

***

#### Post-Receive URLs

This plugin supports the inclusion of GitHub-style Post-Receive URLs. Once added, a post-receive URL will be notified when new changes are pushed to the repository. Two versions of this functionality are available :

* either a GitHub-style POST operation will include json-encoded information about the updated branch

* or an empty GET request will be issued to the given URL

Post-Receive URLs may be added from the repository settings page.

***

#### Automatic Mirror Updates

This plugin can automatically push updates to repository mirrors when new changes are pushed to the repository. Mirrors must grant access to the public key defined in the **redmine_gitolite_admin_id_rsa.pub** public key file, which is displayed for convenience in the repository settings tab.

You have the ability to selectively push branches to the mirror (using the git-push refspec mechanism) rather than mirroring all branches and tags. To utilize this feature, simply select a mirror update mode of *Force Update Remote* or *Fast Forward (unforced)* instead of the default *Complete Mirroring* in the mirror create/edit dialog. More options will then become available.

***

#### Git Smart HTTP

Smart HTTP is an efficient way of communicating with the Git server over HTTP/HTTPS available in Git client version 1.6.6 and newer.
A more detailed description of what Smart HTTP is all about can be found at : [http://progit.org/2010/03/04/smart-http.html](http://progit.org/2010/03/04/smart-http.html).

Redmine Git Hosting plugin integrates code from Scott Schacon's "grack" utility to provide Git Smart HTTP access.

This plugin allows you to automatically enable Smart HTTP access to your repositories.

It is highly recommended that you enable Smart HTTP access **only** via HTTPS -- without encryption this is very insecure. If you want to enable (insecure) access via unencrypted HTTP, go to the repository settings tab and select *HTTPS and HTTP* or *HTTP only* under the *Git Smart HTTP* tab.

Where a password is required, this is your Redmine user password.

Once Smart HTTP is enabled no further configuration is necessary. You will be able to clone/push from/to the HTTP[S] URL specified in the URL bar in the Project/Repository tab.

Also note that you will need to ensure that Basic Auth headers are being passed properly to Rails for this to work properly. In Apache with mod_fcgid this may mean you need to add "Passheader Authorization" into the virtual host configuration file.

Further, if you are proxying requests through a third-party (such as Nginx), you need to make sure that you pass the protocol information onto Redmine so that it can distinguish between HTTP and HTTPS. One way to do this is to use the X-Forwarded-Proto header (which should be set to 'https' when https is in use from the client to the proxy).

Pleaser refer to [Configuration variables]({{ site.baseurl }}/configuration/variables/#gitolite-access-config) for Git Smart HTTP configuration.

This plugin is patched against [CVE-2013-4663](http://www.sec-1.com/blog/2013/redmine-git-hosting-plugin-remote-command-execution).

***

#### Git Daemon

In order to export repositories via the Git daemon (i.e. with URLs of the form 'git://'), you must first install this daemon and give it access to the Gitolite repositories (outside the scope of this README). Once you do so, then control of which repositories are exported depends on two things :

**(1)** the setting of the public flag for the project

**(2)** the setting of the GitDaemon parameter in the project's repository settings.

A repository will be exported via the Git daemon only if its corresponding project is public and its GitDaemon flag is enabled. This plugin handles such repositories by including a special *daemon* key in the *gitolite.conf* file. Presence of this key, in turn, causes Gitolite to insert a *git-daemon-export-ok* flag at the top-level of the corresponding repository. This flag is interpreted by the Git daemon as a sign to export the repository.

Note that the act of changing a project from public to private will set the GitDaemon flag to false automatically (to prevent accidental export of the project via the Git daemon later).

Pleaser refer to [Configuration variables]({{ site.baseurl }}/configuration/variables/#gitolite-access-config) for Git Daemon configuration.

***

#### Caching Options

This plugin includes code for caching output of the Git command, which is called to display the details of the Git repository. Redmine by default calls Git directly every time this information is needed. This can result in relatively long page load times.

This plugin caches the output of Git commands to dramatically improve page load times, roughly a 10x speed increase.

Pleaser refer to [Configuration variables]({{ site.baseurl }}/configuration/variables/#gitolite-cache-config) for Cache configuration.


***

#### Git mailing lists

Pleaser refer to [Configuration variables]({{ site.baseurl }}/configuration/variables/#git-mailing-list-config) for Git Mailing List configuration.

***

#### Sidekiq asynchronous jobs

Pleaser refer to [Step by Step installation]({{ site.baseurl }}/guide/installation/#sidekiq-mode) for Sidekiq asynchronous jobs configuration.

***

#### Default branch selection

The default branch is considered the "base" branch in your repository, which all pull requests and code commits are set against.

By default, your default branch is called ```master```. If you have admin rights over a repository, you can change the default branch on the repository.

***

#### Git Revision Download

This feature adds a download link to the Git repository browser, allowing users to download a snapshot at a given revision. You can download the generated archive in 3 formats :

* tar
* tar.gz
* zip

The major code comes from [Git Revision Download](https://github.com/chantra/redmine_gitrevision_download) and has been adapted to this plugin.

***

#### README Preview

This feature allows to display the content of README file at repository tab.
The README file can be in various format and must have the appropriate extension to be displayed correctly.
Supported format are :

* .markdown, .mdown, .md
* .textile
* .rdoc
* .org
* .creole
* .mediawiki
* .asciidoc, .adoc, .asc

The major code comes from [README at Repositories](https://github.com/simeji/readme_at_repositories) and has been adapted to this plugin.

***

#### Git Config Keys Management

You can manage Git config key/value pairs for each repository.

You are responsible of enabling them in [gitolite.rc](http://gitolite.com/gitolite/rc.html).

***

#### Improved Repository Statistics

Use Highcharts librairy to display nice graphs instead of poor SVG.

***

#### Github Issues Sync

Keep your Github issues synchronized with Redmine !!

Go in your repository settings on Github, then in *Webhooks and Services*, clik on *Add webhook*.

In *Payload URL* field, put Redmine Post Receive url : ```http://redmine.example.com/githooks/post-receive/github/<project-name>```.

The ```<project-name>``` value is the name of the project for which issues will be associated with.

Et voila!

***

#### Browse Archived Repositories

If you are Admin in Redmine you can browse archived repositories by clicking on *Archived repositories* in the top menu.
