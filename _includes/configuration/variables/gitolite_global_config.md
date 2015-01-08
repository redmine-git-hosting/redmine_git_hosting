#### Gitolite Global Config
***

* **:gitolite_temp_dir**

The **:gitolite_temp_dir** parameter points at a temporary directory for locks and Gitolite administrative configurations. This path should end in a path separator, e.g. '/'. For a system in which multiple Redmine sites point at the same Gitolite repository (i.e. share a single Git user), it is very important that all of said sites share the same temporary directory (so that locking works properly). You should probably just leave this parameter with its default value.

    # Default
     :gitolite_temp_dir              => File.join(ENV['HOME'], 'tmp', 'redmine_git_hosting').to_s

***

* **:gitolite_config_file**

The **:gitolite_config_file** parameter specifies the Gitolite configuration file used by Redmine for Redmine-managed repositories. This file (or path) is relative to the Gitolite conf/ directory. The default value of *gitolite.conf* is sufficient for most configurations. If you choose to change this parameter, you will need to place a corresponding **"include"** statement in *gitolite.conf*.

    # Default
    :gitolite_config_file                  => 'gitolite.conf'

***

* **:gitolite_config_has_admin_key**

When this parameter is set to *false*, the plugin will assume that the administrative key is in the main *gitolite.conf* file; when set to *true*, the plugin will attempt to maintain the administrative key in the Redmine-managed Gitolite config file.

    # Default
    :gitolite_config_has_admin_key         => true

***

* **:gitolite_recycle_bin_expiration_time**

Deleted repositories are kept here for up to **:gitolite_recycle_bin_expiration_time** hours

    # Default
    :gitolite_recycle_bin_expiration_time  => '24.0'

***

* **:gitolite_log_level**

Set plugin loglevel : Debug, Info, Warning, Error

    # Default
    :gitolite_log_level                    => 'info'

***

* **:gitolite_log_split**

When set to *true* split logs into different files, one by 'service' (Redmine, Sidekiq worker, Smart HTTP).

    # Default
    :gitolite_log_split                    => false

***
