#### Gitolite SSH Config
***

Setting | Default | Notes
--------|---------|------
**:gitolite_user**            | `git` | The **:gitolite_user** is the user under which Gitolite is installed.
**:gitolite_server_port**     | `22`  | The **:gitolite_server_port** variable should be set to the port which will be used to access the Gitolite repositories via SSH.
**:gitolite_ssh_private_key** | *redmine dir/plugins/redmine_git_hosting/ssh_keys/redmine_gitolite_admin_id_rsa*     | Path to the private key files for accessing the Gitolite admin repository.
**:gitolite_ssh_public_key**  | *redmine dir/plugins/redmine_git_hosting/ssh_keys/redmine_gitolite_admin_id_rsa.pub* | Path to the public key files for accessing the Gitolite admin repository.
