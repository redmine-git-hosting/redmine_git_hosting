#### **(step 2)** Create SSH Keys for user running Redmine

As we need to send commands over SSH in **non-interactive mode**, the SSH key **must not** have passphrase (```-N ''``` argument).

    root$ su - redmine
    redmine$ ssh-keygen -N '' -f REDMINE_ROOT/plugins/redmine_git_hosting/ssh_keys/redmine_gitolite_admin_id_rsa

***
