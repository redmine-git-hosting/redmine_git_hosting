# coding: utf-8
require 'redmine'

require 'redmine_git_hosting'

VERSION_NUMBER = '0.6.1'

Redmine::Plugin.register :redmine_git_hosting do
  name 'Redmine Git Hosting Plugin'
  author 'Eric Bishop, Pedro Algarvio, Christian Käser, Zsolt Parragi, Yunsang Choi, Joshua Hogendorn, Jan Schulz-Hofen, John Kubiatowicz, Nicolas Rodriguez and others'
  description 'Enables Redmine / ChiliProject to control hosting of Git repositories through Gitolite'
  version VERSION_NUMBER
  url 'https://github.com/ericpaulbishop/redmine_git_hosting'
  author_url 'https://github.com/jbox-web'

  settings({
    :partial => 'settings/redmine_git_hosting',
    :default => {
      'gitLockWaitTime'               => '10',
      'gitTempDataDir'                => '/tmp/redmine_git_hosting/',
      'gitScriptDir'                  => '',
      'gitUser'                       => 'git',
      'gitoliteIdentityFile'          => (ENV['HOME'] + "/.ssh/redmine_gitolite_admin_id_rsa").to_s,
      'gitoliteIdentityPublicKeyFile' => (ENV['HOME'] + "/.ssh/redmine_gitolite_admin_id_rsa.pub").to_s,

      'gitConfigFile'                 => 'gitolite.conf',
      'gitConfigHasAdminKey'          => true,
      'gitRepositoryBasePath'         => 'repositories/',
      'gitRedmineSubdir'              => '',
      'gitRepositoryHierarchy'        => false,
      'gitRepositoryIdentUnique'      => true,
      'allProjectsUseGit'             => false,
      'gitDaemonDefault'              => '1',
      'gitHttpDefault'                => '1',
      'gitNotifyCIADefault'           => '0',
      'deleteGitRepositories'         => false,
      'gitRecycleBasePath'            => 'recycle_bin/',
      'gitRecycleExpireTime'          => '24.0',

      'gitServer'                     => 'localhost',
      'httpServer'                    => 'localhost',
      'httpServerSubdir'              => '',
      'gitRepositoriesShowUrl'        => true,

      'gitCacheMaxElements'           => '100',
      'gitCacheMaxTime'               => '-1',
      'gitCacheMaxSize'               => '16',

      'gitHooksAreAsynchronous'       => true,
      'gitHooksDebug'                 => false,
      'gitForceHooksUpdate'           => true,
    }
  })

  project_module :repository do
    permission :create_repository_mirrors, :repository_mirrors => :create
    permission :view_repository_mirrors, :repository_mirrors => :index
    permission :edit_repository_mirrors, :repository_mirrors => :edit
    permission :create_repository_post_receive_urls, :repository_post_receive_urls => :create
    permission :view_repository_post_receive_urls, :repository_post_receive_urls => :index
    permission :edit_repository_post_receive_urls, :repository_post_receive_urls => :edit
    permission :create_deployment_keys, :deployment_credentials => :create_with_key
    permission :view_deployment_keys, :deployment_credentials => :index
    permission :edit_deployment_keys, :deployment_credentials => :edit
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
