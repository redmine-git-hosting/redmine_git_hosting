#### **(step 1)** Clone the plugin
***

Assuming that you have Redmine installed :

```sh
## Before install the plugin, stop Redmine!

root$ su - redmine
redmine$ cd REDMINE_ROOT/plugins
redmine$ git clone https://github.com/ogom/redmine_sidekiq.git
redmine$ git clone https://github.com/jbox-web/redmine_bootstrap_kit.git
redmine$ git clone https://github.com/jbox-web/redmine_git_hosting.git
redmine$ cd redmine_git_hosting/
redmine$ git checkout {{ site.data.project.release.version }}
redmine$ cd REDMINE_ROOT
redmine$ bundle install --without development test
redmine$ RAILS_ENV=production NAME=redmine_git_hosting rake redmine:plugins:migrate

## After install the plugin, start Redmine!
```

Otherwise you can install Redmine by following the wiki : [Redmine Installation](/guide/redmine-installation)

If you're running Redmine with the ```www-data``` user, you should read the wiki and think about changing your configuration.

If you still want to run Redmine with ```www-data``` user, take a look at [this](/configuration/troubleshooting#a_note_about_path_variable).
