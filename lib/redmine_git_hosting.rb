## Redmine SCM adapter
require 'redmine/scm/adapters/xitolite_adapter'

# Set up autoload of patches
Rails.configuration.to_prepare do

  ## Redmine Git Hosting Libs, Patches and Hooks
  rbfiles = Rails.root.join('plugins', 'redmine_git_hosting', 'lib', 'redmine_git_hosting', '**', '*.rb')
  Dir.glob(rbfiles).each do |file|
    require_dependency file
  end

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

      if RedmineGitHosting::Config.get_setting(:gitolite_use_sidekiq, true) && !bypass
        GithostingShellWorker.perform_async(command, object, options)
      else
        RedmineGitHosting::GitoliteWrapper.update(command, object, options)
      end
    end

  end

end
