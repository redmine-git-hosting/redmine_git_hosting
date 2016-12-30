#### **Gitolite Cache Config**
***

Setting | Default | Notes
--------|---------|------
**:gitolite_cache_max_time**     | `86400` | It is the maximum amount of time the Git command will be cached. No matter what, the output of Git commands for a given repository are cleared when new commits are pushed to the server and the post-receive hook is called.
**:gitolite_cache_max_size**     | `16`    | It is the maximum size in Mo of the Git output to cache. Anything above this size won't be cached, and Git will be called directly every time this command is run.
**:gitolite_cache_max_elements** | `2000`  | It is the maximum number of Git commands for which to cache the output.
**:gitolite_cache_adapter**      | `database` | Cache system to use to store GitCache. It can be ```database```, ```memcached``` or ```redis```.

**Important note :**

If using MySQL for your database, you must make sure that the **max_allowed_packet** size is set (in, e.g., /etc/my.cnf) to be at least as large as the value you specify for **:gitolite_cache_max_size** above. If you do not do this, you are likely to get very strange failures of the web server. Such a setting must be placed in the [mysqld] parameter section of this file, for instance :


```
[mysqld]
datadir = /var/lib/mysql
socket  = /var/lib/mysql/mysql.sock
user = mysql
max_allowed_packet = 32M
```

The above example should allow **:gitolite_cache_max_size** == 32M.
