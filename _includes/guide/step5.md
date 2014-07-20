#### **(step 5)** Configure sudo

Run ```visudo``` (you will need root permissions to run this) and set the necessary lines in your sudoers file : assuming Redmine is run as **redmine** and Gitolite is installed as **git**, you need to add this to your sudoers file:

    root$ visudo
    # Add these lines
    redmine        ALL=(git)      NOPASSWD:ALL
    git            ALL=(redmine)  NOPASSWD:ALL

If you have the *requiretty* set in the *Defaults* directive of your sudoers file (it is there by default in CentOS) either remove it or add the following lines below the original directive :

    Defaults:git     !requiretty
    Defaults:redmine !requiretty

*Note: with at least some versions of Ubuntu, you must place any additions to the sudoers file **at the end**, otherwise the line starting with "admin ..." ends up negating these additions -- probably to your great frustration.*

***
