---
layout: default
title: Step By Step installation
---

<div id="toc">
  <h3>Basic install :</h3>

  <ul>
    <li><a href="#step_1_clone_the_plugin">
      <strong>(step 1)</strong> Clone the plugin</a>
    </li>

    <li><a href="#step_2_create_ssh_keys_for_user_running_redmine">
      <strong>(step 2)</strong> Create SSH Keys for user running Redmine</a>
    </li>

    <li><a href="#step_3_user_running_redmine_must_have_rw_access_to_gitoliteadmin">
      <strong>(step 3)</strong> Redmine must have <strong>RW+</strong> access to Gitolite Admin</a>
    </li>

    <li><a href="#step_4_gitolite_must_accept_hook_keys">
      <strong>(step 4)</strong> Gitolite must accept hook keys</a>
    </li>

    <li><a href="#step_5_configure_sudo">
      <strong>(step 5)</strong> Configure sudo</a>
    </li>

    <li><a href="#step_6_add_gitolite_server_in_known_hosts_list">
      <strong>(step 6)</strong> Add Gitolite server in known_hosts list</a>
    </li>

    <li><a href="#step_7_install_ruby_interpreter_for_postreceive_hook">
      <strong>(step 7)</strong> Install Ruby interpreter for post_receive hook</a>
    </li>

    <li><a href="#step_8_finish_installation__configuration">
      <strong>(step 8)</strong> Finish installation - Configuration</a>
    </li>

    <li><a href="#step_9_enjoy">
      <strong>(step 9)</strong> Enjoy!</a>
    </li>
  </ul>

  <ul>
    <h3>Sidekiq mode :</h3>

    <li><a href="#step_1_install_redis_server">
      <strong>(step 1)</strong> Install Redis Server</a>
    </li>

    <li><a href="#step_2_switch_mode">
      <strong>(step 2)</strong> Switch mode</a>
    </li>

    <li><a href="#step_3_run_sidekiq_worker">
      <strong>(step 3)</strong> Run Sidekiq worker</a>
    </li>
  </ul>
</div>


## Basic install

{% include guide/step1.md %}
{% include guide/step2.md %}
{% include guide/step3.md %}
{% include guide/step4.md %}
{% include guide/step5.md %}
{% include guide/step6.md %}
{% include guide/step7.md %}
{% include guide/step8.md %}
{% include guide/step9.md %}

***

## Sidekiq mode


There are additional steps to pass if you want to use the plugin in Sidekiq mode :

#### **(step 1)** Install Redis Server
***

    ## I use Redis Server from packages.dotdeb.org on Debian Wheezy
    ## so you can add this to /etc/apt/sources.list :
    ## deb http://packages.dotdeb.org/  wheezy all
    ## or for Squeeze :
    ## deb http://packages.dotdeb.org/  squeeze all

    ## then
    root$ apt-get update
    root$ apt-get install redis-server

#### **(step 2)** Switch mode
***

Go in *Administration -> Redmine Git Hosting -> Sidekiq tab* then enable Sidekiq mode.

From this point, all actions on projects or repositories are queued in the Redis database.

To execute them you must now run the Sidekiq worker.

#### **(step 3)** Run Sidekiq worker
***

A startup script [```contrib/scripts/sidekiq_git_hosting.sh```](https://github.com/jbox-web/redmine_git_hosting/blob/devel/contrib/scripts/sidekiq_git_hosting.sh) is provided by the plugin.

You should place this script in Redmine user's home bin dir like : ```/home/redmine/bin/sidekiq_git_hosting.sh```.

Normally the Redmine user's bin directory should be in the PATH.

If not, add this in /home/redmine/.profile :

    # Set PATH so it includes user's private bin if it exists
    if [ -d "$HOME/bin" ] ; then
      PATH="$HOME/bin:$PATH"
    fi
