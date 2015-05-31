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

{{ site.data.callouts.alertwarning }}
  Before running ```bundle exec``` you **must** edit plugin's Gemfile (```REDMINE_ROOT/plugin/redmine_git_hosting/Gemfile```) and comment / uncomment the lines corresponding to your Redmine version (2.x or 3.X).
{{ site.data.callouts.end }}

Otherwise you can install Redmine by following the wiki : [How to install Redmine]({{ site.baseurl }}/how-to/install-redmine)

If ```bundle``` command complains on Bitnami Stack, take a look at [this]({{ site.baseurl }}/troubleshooting#bundle-and-bitnami-stack).
