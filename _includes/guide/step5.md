#### **(step 5)** Gitolite must accept hook keys
***

    root$ su - git
    git$ vi (or nano) .gitolite.rc

    ## Look for GIT_CONFIG_KEYS and make it look like :
    GIT_CONFIG_KEYS  =>  '.*',

    ## Enable local code directory
    LOCAL_CODE       =>  "$ENV{HOME}/local"

    ## then save and exit
