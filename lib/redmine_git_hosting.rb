## Redmine Views Hooks
require 'redmine_git_hosting/hooks/add_plugin_icon'
require 'redmine_git_hosting/hooks/add_public_keys_link'
require 'redmine_git_hosting/hooks/display_git_urls_on_project'
require 'redmine_git_hosting/hooks/display_git_urls_on_repository_edit'
require 'redmine_git_hosting/hooks/display_repository_extras'
require 'redmine_git_hosting/hooks/display_repository_readme'
require 'redmine_git_hosting/hooks/display_repository_sidebar'


## Set up autoload of patches
Rails.configuration.to_prepare do

  ## Redmine Git Hosting Libs and Patches
  rbfiles = Rails.root.join('plugins', 'redmine_git_hosting', 'lib', 'redmine_git_hosting', '**', '*.rb')
  Dir.glob(rbfiles).each do |file|
    # Exclude Redmine Views Hooks from Rails loader to avoid multiple calls to hooks on reload in dev environment.
    require_dependency file unless File.dirname(file) == Rails.root.join('plugins', 'redmine_git_hosting', 'lib', 'redmine_git_hosting', 'hooks').to_s
  end

  ## Redmine SCM adapter
  require_dependency 'redmine/scm/adapters/xitolite_adapter'

  ## Gitlab Grack for Git SmartHTTP
  require_dependency 'grack/auth'
  require_dependency 'grack/server'
end

## Hrack for Git Hooks
require 'hrack/init'

module RedmineGitHosting

  class << self

    def logger
      @logger ||= RedmineGitHosting::Log.init_logs!
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
