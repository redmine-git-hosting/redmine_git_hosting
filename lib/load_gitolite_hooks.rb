# frozen_string_literal: true

RedmineGitHosting::GitoliteHooks.register_hooks do
  # Set source dir
  source_dir Rails.root.join('plugins/redmine_git_hosting/contrib/hooks').to_s

  # Declare GitoliteHooks to install

  # Install executable
  gitolite_hook do
    name        'redmine_gitolite.rb'
    source      'post-receive/redmine_gitolite.rb'
    destination 'post-receive'
    executable true
  end

  gitolite_hook do
    name        'mail_notifications.py'
    source      'post-receive/mail_notifications.py'
    destination 'post-receive.d/mail_notifications'
    executable true
  end

  # Install libs
  gitolite_hook do
    name        'git_hosting_config.rb'
    source      'post-receive/lib/git_hosting_config.rb'
    destination 'lib/git_hosting/config.rb'
    executable false
  end

  gitolite_hook do
    name        'git_hosting_custom_hook.rb'
    source      'post-receive/lib/git_hosting_custom_hook.rb'
    destination 'lib/git_hosting/custom_hook.rb'
    executable false
  end

  gitolite_hook do
    name        'git_hosting_http_helper.rb'
    source      'post-receive/lib/git_hosting_http_helper.rb'
    destination 'lib/git_hosting/http_helper.rb'
    executable false
  end

  gitolite_hook do
    name        'git_hosting_hook_logger.rb'
    source      'post-receive/lib/git_hosting_hook_logger.rb'
    destination 'lib/git_hosting/hook_logger.rb'
    executable false
  end

  gitolite_hook do
    name        'git_hosting_post_receive.rb'
    source      'post-receive/lib/git_hosting_post_receive.rb'
    destination 'lib/git_hosting/post_receive.rb'
    executable false
  end

  gitolite_hook do
    name        'git_multimail.py'
    source      'post-receive/lib/git_multimail.py'
    destination 'post-receive.d/git_multimail.py'
    executable false
  end
end

# Gitolite hooks can be found in Redmine root dir or in plugin root dir
[
  Rails.root.join('redmine_git_hosting_hooks.rb').to_s,
  Rails.root.join('plugins/redmine_git_hosting/custom_hooks.rb').to_s
].each do |file|
  require_dependency file if File.exist? file
end

module LoadGitoliteHooks
end
