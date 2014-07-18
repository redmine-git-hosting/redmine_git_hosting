#### Gitolite Access Config
***

* **:ssh_server_domain**

The **:ssh_server_domain** variable should be set to the hostname which will be used to access your Redmine site by SSH, e.g. *www.my-own-personal-git-host-server.com*. This variable may optionally include a port using the ':portnum' syntax, i.e. *www.my-own-person-git-host-server.com:2222*.

    # Default
    :ssh_server_domain                => 'localhost'

* **:http_server_domain**

The **:http_server_domain** variable should be set to the hostname which will be used to access your Redmine site by HTTP, e.g. *www.my-own-personal-git-host-server.com*. This variable may optionally include a port using the ':portnum' syntax, i.e. *www.my-own-person-git-host-server.com:8000*.

    # Default
    :http_server_domain               => 'localhost'

* **:https_server_domain**

The **:https_server_domain** variable should be set to the hostname which will be used to access your Redmine site by HTTPS, e.g. *www.my-own-personal-git-host-server.com*. This variable may optionally include a port using the ':portnum' syntax, i.e. *www.my-own-person-git-host-server.com:8443*.

    # Default
    :https_server_domain              => ''

* **:http_server_subdir**

Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

    # Default
    :http_server_subdir               => ''

* **:show_repositories_url**

**:show_repositories_url** can be disabled to hide the git URL bar in the repository tab.

    # Default
    :show_repositories_url            => true

* **:gitolite_daemon_by_default**

Enable Git daemon for new projects.

    # Default
    :gitolite_daemon_by_default       => 0

* **:gitolite_http_by_default**

Enable Smart HTTP for new projects.

0 => disabled

1 => HTTPS only

2 => HTTPS and HTTP

3 => HTTP only

    # Default
    :gitolite_http_by_default         => 1
