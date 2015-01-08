#### Gitolite Hooks Config
***

* **:gitolite_hooks_are_asynchronous**

Execute Gitolite hooks in background. No output will be display on console.

    # Default
    :gitolite_hooks_are_asynchronous  => true

***

* **:gitolite_force_hooks_update**

Force Gitolite hooks update. This install our provided hooks (those in ```contrib/hooks```) in Gitolite.

    # Default
    :gitolite_force_hooks_update      => true

***

* **:gitolite_hooks_debug**

Execute Gitolite hooks in debug mode.

    # Default
    :gitolite_hooks_debug             => false

***

* **:gitolite_hooks_url**

The Redmine url. This should point to your Redmine instance.

    # Default
    :gitolite_hooks_url             => http://localhost:3000

***
