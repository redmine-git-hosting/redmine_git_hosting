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

If you plan to use [Automatic Repository Initialization](/features/#automatic_repository_initialization) take a look at [this](/configuration/troubleshooting/#initialization_of_the_repo_with_readme_file_does_not_work).
