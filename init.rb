# coding: utf-8

require 'base64'
require 'digest/md5'
require 'digest/sha1'
require 'fileutils'
require 'lockfile'
require 'net/http'
require 'net/ssh'
require 'open3'
require 'stringio'
require 'tmpdir'
require 'uri'
require 'tmpdir'
require 'lockfile'
require 'net/ssh'

#~ require 'gitolite'
#~ require 'sidekiq/web'
#~ require 'sidekiq-unique-jobs'

require 'redmine'

require 'redmine_git_hosting'

# Adds the app/{workers} directories of the plugin to the autoload path
#~ Dir.glob File.expand_path(File.join(File.dirname(__FILE__), 'app', '{workers}')) do |dir|
  #~ ActiveSupport::Dependencies.autoload_paths += [dir]
  #~ RedmineApp::Application.config.eager_load_paths += [dir]
#~ end

REDMINE_ISSUE = 'https://github.com/jbox-web/redmine_git_hosting/issues'
REDMINE_WIKI  = 'https://github.com/jbox-web/redmine_git_hosting/wiki/Configuration-variables'

Redmine::Plugin.register :redmine_git_hosting do
  name 'Redmine Git Hosting Plugin'
  author 'Eric Bishop, Pedro Algarvio, Christian Käser, Zsolt Parragi, Yunsang Choi, Joshua Hogendorn, Jan Schulz-Hofen, John Kubiatowicz, Nicolas Rodriguez and others'
  description 'Enables Redmine to control hosting of Git repositories through Gitolite'
  version '0.6.2'
  url 'https://github.com/jbox-web/redmine_git_hosting'
  author_url 'https://github.com/jbox-web'

  settings({
    :partial => 'settings/redmine_git_hosting',
    :default => {
      # Gitolite SSH Config
      :gitolite_user                  => 'git',
      :gitolite_server_port           => '22',
      :gitolite_ssh_private_key       => File.join(ENV['HOME'], '.ssh', 'redmine_gitolite_admin_id_rsa').to_s,
      :gitolite_ssh_public_key        => File.join(ENV['HOME'], '.ssh', 'redmine_gitolite_admin_id_rsa.pub').to_s,

      # Gitolite Storage Config
      :gitolite_global_storage_dir    => 'repositories/',
      :gitolite_redmine_storage_dir   => '',
      :gitolite_recycle_bin_dir       => 'recycle_bin/',

      # Gitolite Global Config
      :gitolite_temp_dir                     => File.join(ENV['HOME'], 'tmp', 'redmine_git_hosting').to_s,
      :gitolite_script_dir                   => '',
      :gitolite_lock_wait_time               => 10,
      :gitolite_config_file                  => 'gitolite.conf',
      :gitolite_config_has_admin_key         => true,
      :gitolite_recycle_bin_expiration_time  => '24.0',
      :gitolite_log_level                    => 'info',
      :gitolite_log_split                    => false,

      # Gitolite Hooks Config
      :gitolite_hooks_are_asynchronous  => true,
      :gitolite_force_hooks_update      => true,
      :gitolite_hooks_debug             => false,

      # Gitolite Cache Config
      :gitolite_cache_max_time          => '-1',
      :gitolite_cache_max_size          => '16',
      :gitolite_cache_max_elements      => '100',

      # Gitolite Access Config
      :ssh_server_domain                => 'localhost',
      :http_server_domain               => 'localhost',
      :https_server_domain              => '',
      :http_server_subdir               => '',
      :show_repositories_url            => true,
      :gitolite_daemon_by_default       => 0,
      :gitolite_http_by_default         => 1,

      # Redmine Config
      :all_projects_use_git             => false,
      :delete_git_repositories          => false,
      :hierarchical_organisation        => false,
      :unique_repo_identifier           => true,

      # Git Mailing List Config
      :gitolite_notify_cia_by_default        => '0',
      :gitolite_notify_by_default            => 1,
      :gitolite_notify_global_prefix         => '[REDMINE]',
      :gitolite_notify_global_sender_address => 'redmine@example.com',
      :gitolite_notify_global_include        => [],
      :gitolite_notify_global_exclude        => [],
    }
  })

  project_module :repository do
    permission :create_repository_mirrors, :repository_mirrors => :create
    permission :view_repository_mirrors,   :repository_mirrors => :index
    permission :edit_repository_mirrors,   :repository_mirrors => :edit

    permission :create_repository_post_receive_urls, :repository_post_receive_urls => :create
    permission :view_repository_post_receive_urls,   :repository_post_receive_urls => :index
    permission :edit_repository_post_receive_urls,   :repository_post_receive_urls => :edit

    permission :create_deployment_keys, :repository_deployment_credentials => :create_with_key
    permission :view_deployment_keys,   :repository_deployment_credentials => :index
    permission :edit_deployment_keys,   :repository_deployment_credentials => :edit

    permission :create_repository_git_notifications, :repository_git_notifications => :create
    permission :view_repository_git_notifications,   :repository_git_notifications => :index
    permission :edit_repository_git_notifications,   :repository_git_notifications => :edit
    permission :receive_git_notifications,           :gitolite_hooks => :post_receive

    permission :create_gitolite_ssh_key,             :my => :account
  end

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :redmine_git_hosting, { :controller => 'settings', :action => 'plugin', :id => 'redmine_git_hosting' }, :caption => :module_name
  end
end

# initialize observer
# Don't initialize this while doing migration of primary system (i.e. Redmine/Chiliproject)
migrating_primary = (File.basename($0) == "rake" && (ARGV.include?("db:migrate_plugins") || ARGV.include?("redmine:plugins:migrate")))

if Rails::VERSION::MAJOR >= 3
  Rails.configuration.after_initialize do
    if !migrating_primary
      ActiveRecord::Base.observers << GitHostingObserver
      ActiveRecord::Base.observers << GitHostingSettingsObserver
      GitHostingObserver.instance.reload_this_observer
      GitHostingSettingsObserver.instance.reload_this_observer
    end
  end
else
  config.after_initialize do
    if !migrating_primary

      ActiveRecord::Base.observers = ActiveRecord::Base.observers << GitHostingObserver
      ActiveRecord::Base.observers = ActiveRecord::Base.observers << GitHostingSettingsObserver

      ActionController::Dispatcher.to_prepare(:git_hosting_observer_reload) do
        GitHostingObserver.instance.reload_this_observer
      end

      ActionController::Dispatcher.to_prepare(:git_hosting_settings_observer_reload) do
        GitHostingSettingsObserver.instance.reload_this_observer
      end

    end
  end
end
