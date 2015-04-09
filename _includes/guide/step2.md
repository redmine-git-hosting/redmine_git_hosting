#### **(step 2)** Clone the plugin
***

Assuming that you have Redmine installed :

    # Switch user
    root# su - redmine

    # First git clone Bootstrap Kit
    redmine$ cd REDMINE_ROOT/plugins
    redmine$ git clone https://github.com/jbox-web/redmine_bootstrap_kit.git
    redmine$ cd redmine_bootstrap_kit/
    redmine$ git checkout 0.2.3

    # Then Redmine Git Hosting plugin
    redmine$ cd REDMINE_ROOT/plugins
    redmine$ git clone https://github.com/jbox-web/redmine_git_hosting.git
    redmine$ cd redmine_git_hosting/
    redmine$ git checkout {{ site.data.project.release.version }}

    # Install gems and migrate database
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without development test
    redmine$ bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_git_hosting


Otherwise you can install Redmine by following the wiki : [How to install Redmine]({{ site.baseurl }}/how-to/install-redmine)

If you're running Redmine with the ```www-data``` user, take a look at [this]({{ site.baseurl }}/troubleshooting#a-note-about-path-variable).

If ```bundle``` command complains on Bitnami Stack, take a look at [this]({{ site.baseurl }}/troubleshooting#bundle-and-bitnami-stack).
