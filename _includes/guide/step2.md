#### **(step 2)** Clone the plugin
***

Assuming that you have Redmine installed :

    # Switch user
    root# su - redmine

    # First git clone Additionals
    redmine$ cd REDMINE_ROOT/plugins
    redmine$ git clone --branch 3.0.6 https://github.com/AlphaNodes/additionals.git

    # Then Redmine Git Hosting plugin
    redmine$ cd REDMINE_ROOT/plugins
    redmine$ git clone https://github.com/jbox-web/redmine_git_hosting.git
    # last release version is broken, use master branch till next version released!
    # redmine$ cd redmine_git_hosting/
    # redmine$ git checkout {{ site.data.project.release.version }}

    # Install gems and migrate database
    redmine$ cd REDMINE_ROOT
    redmine$ bundle install --without development test
    redmine$ bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=additionals
    redmine$ bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_git_hosting

Otherwise you can install Redmine by following the wiki : [How to install Redmine]({{ site.baseurl }}/how-to/install-redmine).

If ```bundle``` command complains on Bitnami Stack, take a look at [this]({{ site.baseurl }}/troubleshooting#bundle-and-bitnami-stack).
