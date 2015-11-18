#### Gitolite Config File
***

Setting | Default | Notes
--------|---------|------
**:gitolite_config_file**                 | `gitolite.conf` | The **:gitolite_config_file** parameter specifies the Gitolite configuration file used by Redmine for Redmine-managed repositories. This file (or path) is relative to the Gitolite conf/ directory. The default value of *gitolite.conf* is sufficient for most configurations. If you choose to change this parameter, you will need to place a corresponding **"include"** statement in *gitolite.conf*.
**:gitolite_identifier_prefix**           | `redmine_` | Prefix for Gitolite identifiers
**:gitolite_identifier_strip_user_id**    | `false`    | If set to true thee user ID will be removed from Gitolite identifiers
