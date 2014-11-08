#### Gitolite Storage Config

* **:gitolite_global_storage_dir**

The **:gitolite_global_storage_dir** is the path relative to the Git user root where the repositories are located.
This should always be non-empty and should end in a file separator, e.g. '/'.

Since Gitolite always uses *repositories/* as the default place for repositories you probably shouldn't have to change this.

    # Default
    :gitolite_global_storage_dir    => 'repositories/'

* **:gitolite_redmine_storage_dir**

The **:gitolite_redmine_storage_dir** is an optional subdirectory under the **:gitolite_global_storage_dir** which can be used for all plugin-managed repositories.
Its default value is the empty string (no special subdirectory). If you choose to set it, make sure that the resulting path ends in a file separator, e.g. '/'.

    # Default
    :gitolite_redmine_storage_dir   => './'

* **:gitolite_recycle_bin_dir**

The **:gitolite_recycle_bin_dir** is the path relative to the Git user root where deleted repositories are placed. This path should end in a path separator, e.g. '/'.

    # Default
    :gitolite_recycle_bin_dir       => 'recycle_bin/'

* **:gitolite_local_code_dir**

The **:gitolite_local_code_dir** is the path relative to the Git user root where hook files are placed. This path should end in a path separator, e.g. '/'.

    # Default
    :gitolite_local_code_dir       => 'local/'

***
