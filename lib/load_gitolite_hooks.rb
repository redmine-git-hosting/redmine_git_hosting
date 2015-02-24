RedmineGitHosting::GitoliteHooks.register_hooks do
  # Set source dir
  source_dir    Rails.root.join('plugins', 'redmine_git_hosting', 'contrib', 'hooks').to_s

  # Declare GitoliteHooks to install

  # Install executable
  gitolite_hook do
    name        'redmine_gitolite.rb'
    source      'post-receive/redmine_gitolite.rb'
    destination 'post-receive'
    executable   true
  end

  gitolite_hook do
    name        'mail_notifications.py'
    source      'post-receive/mail_notifications.py'
    destination 'post-receive.d/mail_notifications'
    executable  true
  end


  # Install libs
  gitolite_hook do
    name        'git_hosting_config.rb'
    source      'post-receive/lib/git_hosting_config.rb'
    destination 'lib/git_hosting/config.rb'
    executable  false
  end

  gitolite_hook do
    name        'git_hosting_custom_hook.rb'
    source      'post-receive/lib/git_hosting_custom_hook.rb'
    destination 'lib/git_hosting/custom_hook.rb'
    executable   false
  end

  gitolite_hook do
    name        'git_hosting_http_helper.rb'
    source      'post-receive/lib/git_hosting_http_helper.rb'
    destination 'lib/git_hosting/http_helper.rb'
    executable  false
  end

  gitolite_hook do
    name        'git_hosting_hook_logger.rb'
    source      'post-receive/lib/git_hosting_hook_logger.rb'
    destination 'lib/git_hosting/hook_logger.rb'
    executable  false
  end

  gitolite_hook do
    name        'git_hosting_post_receive.rb'
    source      'post-receive/lib/git_hosting_post_receive.rb'
    destination 'lib/git_hosting/post_receive.rb'
    executable  false
  end

  gitolite_hook do
    name        'git_multimail.py'
    source      'post-receive/lib/git_multimail.py'
    destination 'post-receive.d/git_multimail.py'
    executable  false
  end
end


# You can declare here you own hooks to install globally in Gitolite.
# You must set the source directory of the files with the *source_dir* method and
# declare your hooks with *gitolite_hook* method. (see above)
#
# *RedmineGitHosting::GitoliteHooks.register_hooks* can be called multiple times
# with a different *source_dir*.
#
# *name*        : the hook name (to identify the hook)
# *source*      : the source path concatenated with *source_dir*
# *destination* : the destination path on Gitolite side.
#
# The *destination* must be relative.
# The final destination depends on your Gitolite version :
#
# Gitolite v3 : <gitolite_home_dir>/local/hooks/common/
# Gitolite v2 : <gitolite_home_dir>/.gitolite/hooks/common
#
# RedmineGitHosting::GitoliteHooks.register_hooks do
#   # Set source directory : /tmp/foo
#   source_dir    File.join('/', 'tmp', 'foo')
#
#   gitolite_hook do
#     # Hook name
#     name 'bar.rb'
#
#     # Will be /tmp/foo/pre-receive/lib/bar.rb
#     source 'pre-receive/lib/bar.rb'
#
#     # Will be <gitolite_home_dir>/local/hooks/common/lib_toto/test.rb (Gitolite v3)
#     # Will be <gitolite_home_dir>/.gitolite/hooks/common/lib_toto/test.rb (Gitolite v2)
#     destination 'lib_toto/test.rb'
#
#     executable  false
#   end
# end
