#### **(step 4)** Gitolite must accept hook keys
***

```
root$ su - git
git$ vi (or nano) .gitolite.rc
## Look for GIT_CONFIG_KEYS and make it look like :
GIT_CONFIG_KEYS                 =>  '.*',
## then save and exit
```

**Optional :**

If you plan to use [Automatic Repository Initialization](https://github.com/jbox-web/redmine_git_hosting/wiki/Features#automatic-repository-initialization) take a look at [this](https://github.com/jbox-web/redmine_git_hosting/wiki/Troubleshooting#initialization-of-the-repo-with-readme-file-does-not-work).
