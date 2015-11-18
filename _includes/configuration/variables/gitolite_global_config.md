#### Gitolite Global Config
***

Setting | Default | Notes
--------|---------|------
**:gitolite_temp_dir**                    | `redmine dir/tmp/redmine_git_hosting` | The **:gitolite_temp_dir** parameter points at a temporary directory for locks and Gitolite administrative configurations. This path should end in a path separator, e.g. '/'. For a system in which multiple Redmine sites point at the same Gitolite repository (i.e. share a single Git user), it is very important that all of said sites share the same temporary directory (so that locking works properly). You should probably just leave this parameter with its default value.
**:gitolite_recycle_bin_expiration_time** | `24.0`          | Deleted repositories are kept here for up to **:gitolite_recycle_bin_expiration_time** hours
**:gitolite_log_level**                   | `info`          | Set plugin loglevel : Debug, Info, Warning, Error
**:git_config_username**                  | `Redmine Git Hosting` | Git author name for commits
**:git_config_email**                     | `redmine@example.net` | Git author email for commits
