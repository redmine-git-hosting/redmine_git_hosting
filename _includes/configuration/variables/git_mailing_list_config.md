#### Git Mailing List Config
***

* **:gitolite_notify_by_default**

Enable Git notification hook for new repositories?

    # Default
    :gitolite_notify_by_default            => 1

***

* **:gitolite_notify_global_prefix**

Default global prefix for commit mail subject. Used if not set at repository level.

    # Default
    :gitolite_notify_global_prefix         => '[REDMINE]'

***

* **:gitolite_notify_global_sender_address**

Default global sender address. Used if not set at repository level.

    # Default
    :gitolite_notify_global_sender_address => 'redmine@example.com'

***

* **:gitolite_notify_global_include**

Email adresses to include in all mailing lists by default.

    # Default
    :gitolite_notify_global_include        => []

***

* **:gitolite_notify_global_exclude**

Email adresses to exclude in all mailing lists by default.

    # Default
    :gitolite_notify_global_exclude        => []

***
