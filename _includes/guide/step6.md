#### **(step 6)** Configure sudo

As root create the file ```/etc/sudoers.d/redmine``` and put this content in it :

    Defaults:redmine !requiretty
    redmine ALL=(git) NOPASSWD:ALL

Then chmod the file :

    root# chmod 440 /etc/sudoers.d/redmine

***
