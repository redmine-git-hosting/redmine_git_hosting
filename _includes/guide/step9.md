#### **(step 9)** Enjoy!

Unless you want to access your repositories exclusively via Smart HTTP, users will need to set a public key to connect via SSH.

To do this, open a browser, login to Redmine and follow the "My Account" link in the upper right-hand corner of the page.
The right-hand column contains controls for adding your public key(s).

Keys should be unique, that is, the keys you set in Redmine **should not** already exist in the Gitolite repo.

>In particular, **do not re-use** the key you set as the Gitolite admin key.

At this point, the plugin should work. If not, take a look here : [Troubleshooting]({{ site.baseurl }}/configuration/troubleshooting).
