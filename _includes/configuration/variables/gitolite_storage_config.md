#### **Gitolite Storage Config**
***

Setting | Default | Notes
--------|---------|------
**:gitolite_global_storage_dir**  | `repositories/` | The **:gitolite_global_storage_dir** is the path relative to the Git user root where the repositories are located. This should always be non-empty and should end in a file separator, e.g. '/'. Since Gitolite always uses *repositories/* as the default place for repositories you probably shouldn't have to change this.
**:gitolite_redmine_storage_dir** | `''`            | The **:gitolite_redmine_storage_dir** is an optional subdirectory under the **:gitolite_global_storage_dir** which can be used for all plugin-managed repositories. Its default value is the empty string (no special subdirectory). If you choose to set it, make sure that the resulting path ends in a file separator, e.g. '/'.
**:gitolite_recycle_bin_dir**     | `recycle_bin/`  | The **:gitolite_recycle_bin_dir** is the path relative to the Git user root where deleted repositories are placed. This path should end in a path separator, e.g. '/'.
**:gitolite_local_code_dir**      | `local/`        | The **:gitolite_local_code_dir** is the path relative to the Git user root where hook files are placed. This path should end in a path separator, e.g. '/'.
**:gitolite_lib_dir**             | `bin/lib/`      | The **:gitolite_lib_dir** is the path where Gitolite librairies are stored. The default value assumes that Gitolite was installed by hand. (```/usr/share/gitolite3/lib``` with the Debian package)
