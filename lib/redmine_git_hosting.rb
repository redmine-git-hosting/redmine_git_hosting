## Redmine Permissions
require 'redmine_permissions'

## Redmine Menus
Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :redmine_git_hosting, { controller: 'settings', action: 'plugin', id: 'redmine_git_hosting' }, caption: :redmine_git_hosting
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push :archived_repositories, { controller: '/archived_repositories', action: 'index' }, caption: :label_archived_repositories, after: :administration,
            if: Proc.new { User.current.logged? && User.current.admin? }
end

## Redmine SCM
Redmine::Scm::Base.add 'Xitolite'

## Redmine Views Hooks
require 'redmine_git_hosting/hooks/add_plugin_icon'
require 'redmine_git_hosting/hooks/add_public_keys_link'
require 'redmine_git_hosting/hooks/display_git_urls_on_project'
require 'redmine_git_hosting/hooks/display_git_urls_on_repository_edit'
require 'redmine_git_hosting/hooks/display_git_urls_on_repository_show'
require 'redmine_git_hosting/hooks/display_repository_extras'
require 'redmine_git_hosting/hooks/display_repository_readme'
require 'redmine_git_hosting/hooks/display_repository_sidebar'

## Redmine Plugin Loader
require 'redmine_git_hosting/redmine_plugin_loader'

module RedmineGitHosting
  extend self
  extend RedminePluginLoader

  Haml::Template.options[:attr_wrapper] = '"'

  set_plugin_name       'redmine_git_hosting'

  set_autoloaded_paths  'forms',
                        'presenters',
                        'reports',
                        'services',
                        'use_cases',
                        ['controllers', 'concerns'],
                        ['models', 'concerns']


  def logger
    @logger ||= RedmineGitHosting::Logger.init_logs!('RedmineGitHosting', logfile, loglevel)
  end


  def logfile
    Rails.root.join('log', 'git_hosting.log')
  end


  def loglevel
    case RedmineGitHosting::Config.gitolite_log_level
    when 'debug' then
      Logger::DEBUG
    when 'info' then
      Logger::INFO
    when 'warn' then
      Logger::WARN
    when 'error' then
      Logger::ERROR
    else
      Logger::INFO
    end
  end
end


## Set up autoload of patches
Rails.configuration.to_prepare do
  ## Redmine Git Hosting Libs and Patches
  RedmineGitHosting.load_plugin!

  ## Redmine SCM adapter
  require_dependency 'redmine/scm/adapters/xitolite_adapter'

  ## Gitlab Grack for Git SmartHTTP
  require_dependency 'grack/auth'
  require_dependency 'grack/server'

  ## Hrack for Git Hooks
  require 'hrack/init'

  ## Extensions for Faker
  if !Rails.env.production?
    require_dependency 'core_ext/faker/git'
    require_dependency 'core_ext/faker/ssh'
  end
end
