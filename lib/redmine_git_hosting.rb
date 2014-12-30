## Redmine SCM adapter
require 'redmine/scm/adapters/xitolite_adapter'

# Set up autoload of patches
Rails.configuration.to_prepare do

  ## Redmine Git Hosting Libs, Patches and Hooks
  rbfiles = Rails.root.join('plugins', 'redmine_git_hosting', 'lib', 'redmine_git_hosting', '**', '*.rb')
  Dir.glob(rbfiles).each do |file|
    require_dependency file
  end

  require_dependency 'grack/auth'
  require_dependency 'grack/server'

end


module RedmineGitHosting

  class << self

    @@logger = nil


    def logger
      @@logger ||= RedmineGitHosting::Log.init_logs!
    end


    def resync_gitolite(command, object, options = {})
      if options.has_key?(:bypass_sidekiq) && options[:bypass_sidekiq] == true
        bypass = true
      else
        bypass = false
      end

      if RedmineGitHosting::Config.gitolite_use_sidekiq? && !bypass
        GithostingShellWorker.perform_async(command, object, options)
      else
        RedmineGitHosting::GitoliteWrapper.resync_gitolite(command, object, options)
      end
    end

  end

end
