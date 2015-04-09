#### **(step 9)** Finish installation - Configuration
***

The plugin is now installed, you can restart Redmine :)

But you **must** set some additional settings :

1. Enable Xitolite repositories in *Administration -> Settings -> Repositories*
2. Configure plugin settings in *Administration -> Redmine Git Hosting*, specially :
  * SSH Keys path
  * Temp dir path
  * Access urls
  * Hooks url
3. Check your installation in *Administration -> Redmine Git Hosting* *Config Checks* tab.
4. Set some permissions on *Administration -> Roles* page, **particularly if you want users to be able to create SSH keys**.

Before configuring the plugin you should take a look at this : [Repositories Storage Configuration Strategy]({{ site.baseurl }}/configuration/notes/#repositories-storage-configuration-strategy).

If you're using a Bitnami Stack (again) : you **must** properly configure the temp directory. [Here's how]({{ site.baseurl }}/troubleshooting#temp-dir-and-bitnami-stack).

{{ site.data.callouts.alertwarning }}
  You may need to restart Redmine after changing settings are some of them are put in cache.
{{ site.data.callouts.end }}
