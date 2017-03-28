# Redmine Permissions
require 'redmine_permissions'

# Redmine Menus
require 'redmine_menus'

# Redmine Views Hooks
require 'redmine_view_hooks'

# Redmine SCM
Redmine::Scm::Base.add 'Xitolite'

module RedmineGitHosting
  extend self

  # Load RedminePluginLoader
  require 'redmine_git_hosting/redmine_plugin_loader'
  extend RedminePluginLoader

  Haml::Template.options[:attr_wrapper] = '"'
  Haml::Template.options[:remove_whitespace] = true

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


# Set up autoload of patches
Rails.configuration.to_prepare do
  # Redmine Git Hosting Libs and Patches
  RedmineGitHosting.load_plugin!

  # Redmine SCM adapter
  require_dependency 'redmine/scm/adapters/xitolite_adapter'

  require 'hrack/init'

  # Extensions for Faker
  unless Rails.env.production?
    require_dependency 'core_ext/faker/git'
    require_dependency 'core_ext/faker/ssh'
  end
end
