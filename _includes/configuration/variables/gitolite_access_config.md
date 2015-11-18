#### Gitolite Access Config
***

Setting | Default | Notes
--------|---------|------
**:ssh_server_domain**          | `localhost` | The **:ssh_server_domain** variable should be set to the hostname which will be used to access your Redmine site by SSH, e.g. *www.my-own-personal-git-host-server.com*. This variable may optionally include a port using the ':portnum' syntax, i.e. *www.my-own-person-git-host-server.com:2222*.
**:http_server_domain**         | `localhost` | The **:http_server_domain** variable should be set to the hostname which will be used to access your Redmine site by HTTP, e.g. *www.my-own-personal-git-host-server.com*. This variable may optionally include a port using the ':portnum' syntax, i.e. *www.my-own-person-git-host-server.com:8000*.
**:https_server_domain**        | `localhost` | The **:https_server_domain** variable should be set to the hostname which will be used to access your Redmine site by HTTPS, e.g. *www.my-own-personal-git-host-server.com*. This variable may optionally include a port using the ':portnum' syntax, i.e. *www.my-own-person-git-host-server.com:8443*. Set to empty if you don't use it.
**:http_server_subdir**         | `''`   | The **:http_server_subdir** variable should be set to the subdir which will be used to access your Redmine site by HTTP.
**:show_repositories_url**      | `true` | Repositories URLs can be hidden in the repository tab.
**:gitolite_daemon_by_default** | `true` | Enable Git daemon for new projects.
**:gitolite_http_by_default**   | `1`    | Enable Smart HTTP for new projects. (0 => disabled, 1 => HTTPS only, 2 => HTTPS and HTTP, 3 => HTTP only)
