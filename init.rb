# coding: utf-8
require 'redmine'

require 'redmine_git_hosting'

# Adds the app/{workers} directories of the plugin to the autoload path
#~ Dir.glob File.expand_path(File.join(File.dirname(__FILE__), 'app', '{workers}')) do |dir|
  #~ ActiveSupport::Dependencies.autoload_paths += [dir]
  #~ RedmineApp::Application.config.eager_load_paths += [dir]
#~ end

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
      'gitUser'                       => 'git',
      'sshServerLocalPort'            => '22',
      'gitoliteIdentityFile'          => File.join(ENV['HOME'], '.ssh', 'redmine_gitolite_admin_id_rsa').to_s,
      'gitoliteIdentityPublicKeyFile' => File.join(ENV['HOME'], '.ssh', 'redmine_gitolite_admin_id_rsa.pub').to_s,

      # Gitolite Storage Config
      'gitRepositoryBasePath'         => 'repositories/',
      'gitRedmineSubdir'              => '',
      'gitRecycleBasePath'            => 'recycle_bin/',

      # Gitolite Global Config
      'gitTempDataDir'                => File.join(ENV['HOME'], 'tmp', 'redmine_git_hosting').to_s,
      'gitScriptDir'                  => '',
      'gitLockWaitTime'                      => '10',
      'gitConfigFile'                        => 'gitolite.conf',
      'gitConfigHasAdminKey'                 => true,
      'gitRecycleExpireTime'                 => '24.0',
      'gitoliteLogLevel'                     => 'info',
      'gitoliteLogSplit'                     => false,

      # Gitolite Hooks Config
      'gitHooksAreAsynchronous'         => true,
      'gitForceHooksUpdate'             => true,
      'gitHooksDebug'                   => false,

      # Gitolite Cache Config
      'gitCacheMaxTime'                 => '-1',
      'gitCacheMaxSize'                 => '16',
      'gitCacheMaxElements'             => '100',

      # Gitolite Access Config
      'gitServer'                       => 'localhost',
      'httpServer'                      => 'localhost',

      'httpServerSubdir'                => '',
      'gitRepositoriesShowUrl'          => true,
      'gitDaemonDefault'                => 0,
      'gitHttpDefault'                  => 1,

      # Redmine Config
      'allProjectsUseGit'               => false,
      'deleteGitRepositories'           => false,
      'gitRepositoryHierarchy'          => false,
      'gitRepositoryIdentUnique'        => true,

      'gitNotifyCIADefault'             => '0',
    }
  })

  project_module :repository do
    permission :create_repository_mirrors, :repository_mirrors => :create
    permission :view_repository_mirrors,   :repository_mirrors => :index
    permission :edit_repository_mirrors,   :repository_mirrors => :edit

    permission :create_repository_post_receive_urls, :repository_post_receive_urls => :create
    permission :view_repository_post_receive_urls,   :repository_post_receive_urls => :index
    permission :edit_repository_post_receive_urls,   :repository_post_receive_urls => :edit

    permission :create_deployment_keys, :deployment_credentials => :create_with_key
    permission :view_deployment_keys,   :deployment_credentials => :index
    permission :edit_deployment_keys,   :deployment_credentials => :edit

    permission :create_gitolite_ssh_key,             :my => :account
  end

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :redmine_git_hosting, { :controller => 'settings', :action => 'plugin', :id => 'redmine_git_hosting' }, :caption => :module_name
  end
end

# initialize observer
# Don't initialize this while doing migration of primary system (i.e. Redmine/Chiliproject)
migrating_primary = (File.basename($0) == "rake" && ARGV.include?("db:migrate"))

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
