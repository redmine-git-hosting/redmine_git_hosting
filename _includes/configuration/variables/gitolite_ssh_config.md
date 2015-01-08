#### Gitolite SSH Config
***

* **:gitolite_user**

The **:gitolite_user** is the user under which Gitolite is installed.

    # Default
    :gitolite_user                  => 'git'

***

* **:gitolite_server_port**

The **:gitolite_server_port** variable should be set to the port which will be used to access the Gitolite repositories via SSH. In most configurations, the **:gitolite_server_port** variable will be the standard SSH port '22'.

    # Default
    :gitolite_server_port           => '22'

***

* **:gitolite_ssh_private_key**

Path to the private key files for accessing the Gitolite admin repository.

    # Default
    :gitolite_ssh_private_key       => Rails.root.join('plugins', 'redmine_git_hosting', 'ssh_keys', 'redmine_gitolite_admin_id_rsa').to_s

***

* **:gitolite_ssh_public_key**

Path to the public key files for accessing the Gitolite admin repository.

    # Default
    :gitolite_ssh_public_key        => Rails.root.join('plugins', 'redmine_git_hosting', 'ssh_keys', 'redmine_gitolite_admin_id_rsa.pub').to_s

***
