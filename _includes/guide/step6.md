#### **(step 6)** Add Gitolite server in known_hosts list

Make sure that Redmine user has Gitolite server in his known_hosts list. This is also a good check to see if Gitolite works.

It **should not** ask you for a password.

    root$ su - redmine
    redmine$ ssh -i REDMINE_ROOT/plugins/redmine_git_hosting/ssh_keys/redmine_gitolite_admin_id_rsa git@localhost info
    # accept key

You should get something like that :

    hello redmine_gitolite_admin_id_rsa, this is gitolite v2.3.1-0-g912a8bd-dt running on git 1.7.2.5
    the gitolite config gives you the following access:
        R   W  gitolite-admin
        @R_ @W_ testing

Or

    hello redmine_gitolite_admin_id_rsa, this is git@dev running gitolite3 v3.3-11-ga1aba93 on git 1.7.2.5
        R W  gitolite-admin
        R W  testing


<div class="alert alert-success" role="alert">
  <p>If you get one of these messages, you're on the right way ;)</a></p>
</div>

***
