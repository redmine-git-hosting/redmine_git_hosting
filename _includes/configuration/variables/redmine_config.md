#### Redmine Config
***

* **:all_projects_use_git (Automatic Repository Creation)**

Can be enabled to automatically create a new Git repository every time you create a new project. You won't have to create the project and then create the repository, this will be done all it one step.

    # Default
    :all_projects_use_git             => false

***

* **:init_repositories_on_create (Automatic Repository Initialization)**

Can be enabled to automatically initialize a new Git repository with a README file (à la Github).

    # Default
    :init_repositories_on_create      => false

***

* **:delete_git_repositories**

Can be enabled to let this plugin control repository deletion. By default, this feature is disabled and when a repository is deleted in Redmine, it is not deleted in Gitolite. This is a safety feature to prevent the accidental loss of data. If this feature is enabled, the safety is turned off and the repository files will be deleted when the Project/Repository is deleted in Redmine. Note, however, that even when this feature is enabled, deleted repositories are placed into a "recycle_bin" for a configurable amount of time (defaulting to 24 hours) and can be recovered by recreating the project or the repository in Redmine with the same **identifier**.

    # Default
    :delete_git_repositories          => true

***

* **:hierarchical_organisation**

The **:hierarchical_organisation** variable is a boolean value which denotes whether or not the plugin-managed repositories are placed into a hierarchy that mirrors the project hierarchy. Its value is either 'true' (default) or 'false'.

As an example of the significance of the previous variable, suppose that project-3 is a child of project-2 which is a child of project-1. Assume **:gitolite_global_storage_dir** == "repository/" and **:gitolite_redmine_storage_dir** == "redmine". When **:hierarchical_organisation** is set to *true*, project-3.git will be stored in ```repository/redmine/project-1/project-2/project-3.git```, which will further be reflected in the SSH access URL of ```repository/redmine/project-1/project-2/project-3.git```. In contrast, when **:hierarchical_organisation** is set to *false*, project-3.git will be stored directly under ```repository/redmine``` -- regardless of the number and identity of any parents that it might have.

    # Default
    :hierarchical_organisation        => true
