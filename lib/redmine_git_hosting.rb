# frozen_string_literal: true

# Redmine Hooks
require 'redmine_git_hosting/hooks'

# Redmine SCM
Redmine::Scm::Base.add 'Xitolite'

module RedmineGitHosting
  extend self

  VERSION = '5.0.1-master'

  # Load RedminePluginLoader
  require 'redmine_git_hosting/redmine_plugin_loader'
  extend RedminePluginLoader

  set_plugin_name       'redmine_git_hosting'

  set_autoloaded_paths  'forms',
                        'presenters',
                        'reports',
                        'services',
                        'use_cases',
                        %w[controllers concerns],
                        %w[models concerns]

  def logger
    @logger ||= if ['Journald::Logger', 'Journald::TraceLogger'].include? Rails.logger.class.to_s
                  RedmineGitHosting::JournalLogger.init_logs! logprogname, loglevel
                else
                  RedmineGitHosting::FileLogger.init_logs! logprogname, logfile, loglevel
                end
  end

  def logprogname
    'redmine_git_hosting'
  end

  def logfile
    Rails.root.join 'log/git_hosting.log'
  end

  def loglevel
    case RedmineGitHosting::Config.gitolite_log_level
    when 'debug'
      Logger::DEBUG
    when 'warn'
      Logger::WARN
    when 'error'
      Logger::ERROR
    else
      Logger::INFO
    end
  end

  def additionals_help_items
    [{ title: 'Git Hosting',
       url: 'http://redmine-git-hosting.io/how-to/',
       admin: true }]
  end
end

# Set up autoload of patches
Rails.configuration.to_prepare do
  # Redmine Git Hosting Libs and Patches
  RedmineGitHosting.load_plugin!

  # Redmine SCM adapter
  require_dependency 'redmine/scm/adapters/xitolite_adapter'

  require 'hrack/bundle'
end
