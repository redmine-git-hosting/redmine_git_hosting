#### **(step 8)** Install Ruby interpreter for post-receive hook

Our post-receive hook is triggered after each commit and is used to fetch changesets in Redmine. As it is written in Ruby, you need to install Ruby on your server. Note that this does not conflict with RVM. Ruby 1.9 at least is required for the hooks.

    root$ apt-get install ruby
    # or
    root$ yum install ruby

***
