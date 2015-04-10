#### Gitolite Global Config
***

Setting | Default | Notes
--------|---------|------
**:gitolite_temp_dir**                    | `redmine dir/tmp/redmine_git_hosting` | The **:gitolite_temp_dir** parameter points at a temporary directory for locks and Gitolite administrative configurations. This path should end in a path separator, e.g. '/'. For a system in which multiple Redmine sites point at the same Gitolite repository (i.e. share a single Git user), it is very important that all of said sites share the same temporary directory (so that locking works properly). You should probably just leave this parameter with its default value.
**:gitolite_config_file**                 | `gitolite.conf` | The **:gitolite_config_file** parameter specifies the Gitolite configuration file used by Redmine for Redmine-managed repositories. This file (or path) is relative to the Gitolite conf/ directory. The default value of *gitolite.conf* is sufficient for most configurations. If you choose to change this parameter, you will need to place a corresponding **"include"** statement in *gitolite.conf*.
**:gitolite_recycle_bin_expiration_time** | `24.0`          | Deleted repositories are kept here for up to **:gitolite_recycle_bin_expiration_time** hours
**:gitolite_log_level**                   | `info`          | Set plugin loglevel : Debug, Info, Warning, Error
