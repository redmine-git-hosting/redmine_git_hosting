#### **(step 3)** User running Redmine must have **RW+** access to gitolite-admin

Assuming that you have Gitolite installed :

    repo    gitolite-admin
            RW+     =       redmine_gitolite_admin_id_rsa


Otherwise you can install Gitolite (v3) by following this :

    Server requirements:

      * any unix system
      * sh
      * git 1.6.6+
      * perl 5.8.8+
      * openssh 5.0+
      * a dedicated userid to host the repos (in this document, we assume it
        is 'git'), with shell access ONLY by 'su - git' from some other userid
        on the same server.

    Steps to install:

      * login as 'git' as described above

      * make sure ~/.ssh/authorized_keys is empty or non-existent

      * make sure **Redmine SSH public key** is available at $HOME/redmine_gitolite_admin_id_rsa.pub

      * add this in ~/.profile

            # set PATH so it includes user private bin if it exists
            if [ -d "$HOME/bin" ] ; then
              PATH="$PATH:$HOME/bin"
            fi

      * run the following commands:

            root$ su - git
            git$ mkdir $HOME/bin
            git$ source $HOME/.profile
            git$ git clone git://github.com/sitaramc/gitolite
            git$ gitolite/install -to $HOME/bin
            git$ gitolite setup -pk redmine_gitolite_admin_id_rsa.pub


<div class="alert alert-warning" role="alert" markdown="1">
If you are running Gitolite 3 don't forget to [patch it!]({{ site.baseurl }}/configuration/troubleshooting/#hook-errors-while-pushing-over-https).
</div>

***
