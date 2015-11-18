#### Redmine Config
***

Setting | Default | Notes
--------|---------|------
**:redmine_has_rw_access_on_all_repos**    | `true` | If set to true Redmine will have RW access on all Gitolite repositories.
**:all_projects_use_git**        | `false` | Can be enabled to automatically create a new Git repository every time you create a new project. You won't have to create the project and then create the repository, this will be done all it one step.
**:init_repositories_on_create** | `false` | Can be enabled to automatically initialize a new Git repository with a README file (à la Github).
**:delete_git_repositories**     | `true`  | Can be enabled to let this plugin control repository deletion. By default, this feature is disabled and when a repository is deleted in Redmine, it is not deleted in Gitolite. This is a safety feature to prevent the accidental loss of data. If this feature is enabled, the safety is turned off and the repository files will be deleted when the Project/Repository is deleted in Redmine. Note, however, that even when this feature is enabled, deleted repositories are placed into a "recycle_bin" for a configurable amount of time (defaulting to 24 hours) and can be recovered by recreating the project or the repository in Redmine with the same **identifier**.
**:hierarchical_organisation**   | `true`  | The **:hierarchical_organisation** variable is a boolean value which denotes whether or not the plugin-managed repositories are placed into a hierarchy that mirrors the project hierarchy.
**:gitolite_use_sidekiq**        | `false` | If set to true the plugin will use Sidekiq to launch asynchronous jobs.
