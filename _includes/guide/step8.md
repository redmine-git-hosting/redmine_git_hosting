#### **(step 8)** Finish installation - Configuration

The plugin is now installed, but you **must** set some additional settings on the *Administration -> Redmine Git Hosting* page.

Before configuring the plugin you should take a look at this : [Repositories Storage Configuration Strategy]({{ site.baseurl }}/configuration/notes/#repositories-storage-configuration-strategy).

You will able to check your installation in *Config Checks* tabs.

<div class="alert alert-warning" role="alert" markdown="1">
You must also set some permissions on *Administration -> Roles* page, **particularly if you want users to be able to create SSH keys**.
</div>

Unless you want to access your repositories exclusively via Smart HTTP, users will need to set a public key to connect via SSH.

To do this, open a browser, login to Redmine and follow the "My Account" link in the upper right-hand corner of the page.

The right-hand column contains controls for adding your public key(s).

SSH Keys should be unique, that is, the keys you set in Redmine **should not** already exist in the Gitolite repo.

<div class="alert alert-danger" role="alert" markdown="1">
In particular, **do not re-use the key you set as the Gitolite admin key**.
</div>

At this point, the plugin should work. If not, take a look here : [Troubleshooting]({{ site.baseurl }}/configuration/troubleshooting).

[Let me know if it works ! (or not)](https://github.com/jbox-web/redmine_git_hosting/issues/339)
