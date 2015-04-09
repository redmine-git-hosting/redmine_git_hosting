#### **(step 1)** Install dependencies
***

{{ site.data.callouts.alertwarning }}
  Before update the plugin don't forget to backup your database and stop Redmine!
{{ site.data.callouts.end }}

    # Install dependencies (On Debian/Ubuntu)
    root# apt-get install build-essential libssh2-1 libssh2-1-dev cmake libgpg-error-dev

    # Install dependencies (On Fedora/CentoS/RedHat)
    root# yum groupinstall "Development Tools"
    root# yum install libssh2 libssh2-devel cmake libgpg-error-devel

If you're using Bitnami Redmine Stack you must run this **before doing anything** to prepare the installation : [Bitnami Installation]({{ site.baseurl }}/how-to/install-on-bitnami).
