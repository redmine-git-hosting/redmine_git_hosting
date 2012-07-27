# coding: utf-8
require 'redmine'

require File.join(File.dirname(__FILE__), 'app', 'models', 'git_repository_extra')
require File.join(File.dirname(__FILE__), 'app', 'models', 'git_cia_notification')

Redmine::Plugin.register :redmine_git_hosting do
	name 'Redmine Git Hosting Plugin'
	author 'Eric Bishop, Pedro Algarvio, Christian Käser, Zsolt Parragi, Yunsang Choi, Joshua Hogendorn, Jan Schulz-Hofen, John Kubiatowicz and others'
	description 'Enables Redmine / ChiliProject to control hosting of git repositories'
	version '0.4.5x'
	url 'https://github.com/ericpaulbishop/redmine_git_hosting'

	settings :default => {
		'httpServer' => 'localhost',
		'httpServerSubdir' => '',
		'gitServer' => 'localhost',
		'gitUser' => 'git',
		'gitConfigPath' => 'gitolite.conf', # Redmine gitolite config file
		'gitConfigHasAdminKey' => 'true',   # Conf file should have admin key
		'gitRepositoryBasePath' => 'repositories/',
		'gitRedmineSubdir' => '',
		'gitRepositoryHierarchy' => 'true',
		'gitRecycleBasePath' => 'recycle_bin/',
		'gitRecycleExpireTime' => '24.0',
		'gitLockWaitTime' => '10',
		'gitoliteIdentityFile' => RAILS_ROOT + '/.ssh/gitolite_admin_id_rsa',
		'gitoliteIdentityPublicKeyFile' => RAILS_ROOT + '/.ssh/gitolite_admin_id_rsa.pub',
		'allProjectsUseGit' => 'false',
		'gitDaemonDefault' => '1',   # Default is Daemon enabled
		'gitHttpDefault' => '1',     # Default is HTTP_ONLY
		'gitNotifyCIADefault' => '0', # Default is CIA Notification disabled
		'deleteGitRepositories' => 'false',
		'gitRepositoriesShowUrl' => 'true',
		'gitCacheMaxTime' => '-1',
		'gitCacheMaxElements' => '100',
		'gitCacheMaxSize' => '16',
		'gitHooksDebug' => 'false',
		'gitHooksAreAsynchronous' => 'true',
		'gitTempDataDir' => '/tmp/redmine_git_hosting/',
		'gitScriptDir' => '',
		'gitForceHooksUpdate' => 'true'
		},
		:partial => 'redmine_git_hosting'
		project_module :repository do
			permission :create_repository_mirrors, :repository_mirrors => :create
			permission :view_repository_mirrors, :repository_mirrors => :index
			permission :edit_repository_mirrors, :repository_mirrors => :edit
			permission :create_repository_post_receive_urls, :repository_post_receive_urls => :create
			permission :view_repository_post_receive_urls, :repository_post_receive_urls => :index
			permission :edit_repository_post_receive_urls, :repository_post_receive_urls => :edit
		end
end

# Set up autoload of patches
Dir[File.dirname(__FILE__)+"/lib/git_hosting/patches/*.rb"].each do |patch|
	require_dependency 'git_hosting/patches/'+File.basename(patch,".rb")
end

# initialize hooks
class GitProjectShowHook < Redmine::Hook::ViewListener
	render_on :view_projects_show_left, :partial => 'git_urls'
end

class GitRepoUrlHook < Redmine::Hook::ViewListener
	render_on :view_repositories_show_contextual, :partial => 'git_urls'
end


# initialize observer
config.after_initialize do
	if config.action_controller.perform_caching
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

