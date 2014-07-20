#### **(step 4)** Gitolite must accept hook keys

    root$ su - git
    git$ vi (or nano) .gitolite.rc
    ## Look for GIT_CONFIG_KEYS and make it look like :
    GIT_CONFIG_KEYS                 =>  '.*',
    ## then save and exit

<div class="alert alert-warning" role="alert" markdown="1">
If you plan to use [Automatic Repository Initialization]({{ site.baseurl }}/features/#automatic-repository-initialization) take a look at [this]({{ site.baseurl }}/configuration/troubleshooting/#initialization-of-the-repo-with-readme-file-does-not-work).
</div>

***
