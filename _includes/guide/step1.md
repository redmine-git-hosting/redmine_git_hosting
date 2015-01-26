#### **(step 1)** Clone the plugin

<div class="alert alert-warning" role="alert">Before update the plugin don't forget to backup your database and stop Redmine!</div>

Assuming that you have Redmine installed :

    # Install dependencies
    root$ apt-get install libssh2-1 libssh2-1-dev cmake libgpg-error-dev

    # Switch user
    root$ su - redmine

    # First git clone Bootstrap Kit
    redmine$ cd REDMINE_ROOT/plugins
    redmine$ git clone https://github.com/jbox-web/redmine_bootstrap_kit.git
    redmine$ cd redmine_bootstrap_kit/
    redmine$ git checkout v0.2.0

    # Then Redmine Git Hosting plugin
    redmine$ cd REDMINE_ROOT/plugins
    redmine$ git clone https://github.com/jbox-web/redmine_git_hosting.git
    redmine$ cd redmine_git_hosting/
    redmine$ git checkout {{ site.data.project.release.version }}

    # Install gems and migrate database
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without development test
    redmine$ bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_git_hosting

    ## After install the plugin, start Redmine!

Otherwise you can install Redmine by following the wiki : [Redmine Installation]({{ site.baseurl }}/guide/redmine-installation)

If you're running Redmine with the ```www-data``` user, you should read the wiki and think about changing your configuration.

If you still want to run Redmine with ```www-data``` user, take a look at [this]({{ site.baseurl }}/configuration/troubleshooting#a-note-about-path-variable).

***
