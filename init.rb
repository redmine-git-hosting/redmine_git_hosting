# coding: utf-8
require 'redmine'
require_dependency 'principal'
require_dependency 'user'

require File.join(File.dirname(__FILE__), 'app', 'models', 'git_repository_extra')
require File.join(File.dirname(__FILE__), 'app', 'models', 'git_cia_notification')

Redmine::Plugin.register :redmine_git_hosting do
	name 'Redmine Git Hosting Plugin'
	author 'Eric Bishop, Pedro Algarvio, Christian Käser, Zsolt Parragi, Yunsang Choi, Joshua Hogendorn, Jan Schulz-Hofen, John Kubiatowicz and others'
	description 'Enables Redmine / ChiliProject to control hosting of git repositories'
	version '0.4.4x'
	url 'https://github.com/ericpaulbishop/redmine_git_hosting'

	settings :default => {
		'httpServer' => 'localhost',
    		'httpServerSubdir' => '',
		'gitServer' => 'localhost',
		'gitUser' => 'git',
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
		'gitScriptDir' => ''
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
require "dispatcher"
Dispatcher.to_prepare :redmine_git_patches do

  require_dependency 'git_hosting'

  # initialize association from project -> repository mirrors
  Project.send(:has_many, :repository_mirrors, :dependent => :destroy)
  
  # initialize association from project -> repository post receive urls
  Project.send(:has_many, :repository_post_receive_urls, :dependent => :destroy)

  require_dependency 'projects_controller'
  require 'git_hosting/patches/projects_controller_patch'
  ProjectsController.send(:include, GitHosting::Patches::ProjectsControllerPatch)

  require_dependency 'repositories_controller'
  require 'git_hosting/patches/repositories_controller_patch'
  RepositoriesController.send(:include, GitHosting::Patches::RepositoriesControllerPatch)

  require_dependency 'repository'
  require 'git_hosting/patches/repository_patch'
  Repository.send(:include, GitHosting::Patches::RepositoryPatch)

  require 'stringio'
  require_dependency 'redmine/scm/adapters/git_adapter'
  require 'git_hosting/patches/git_adapter_patch'
  Redmine::Scm::Adapters::GitAdapter.send(:include, GitHosting::Patches::GitAdapterPatch)

  require_dependency 'groups_controller'
  require 'git_hosting/patches/groups_controller_patch'
  GroupsController.send(:include, GitHosting::Patches::GroupsControllerPatch)

  require_dependency 'repository'
  require_dependency 'repository/git'
  require 'git_hosting/patches/git_repository_patch'
  Repository::Git.send(:include, GitHosting::Patches::GitRepositoryPatch)

  require_dependency 'sys_controller'
  require 'git_hosting/patches/sys_controller_patch'
  SysController.send(:include, GitHosting::Patches::SysControllerPatch)

  require_dependency 'members_controller'
  require 'git_hosting/patches/members_controller_patch'
  MembersController.send(:include, GitHosting::Patches::MembersControllerPatch)

  # initialize association from user -> public keys
  User.send(:has_many, :gitolite_public_keys, :dependent => :destroy)

  require_dependency 'users_controller'
  require 'git_hosting/patches/users_controller_patch'
  UsersController.send(:include, GitHosting::Patches::UsersControllerPatch)

  require_dependency 'roles_controller'
  require 'git_hosting/patches/roles_controller_patch'
  RolesController.send(:include, GitHosting::Patches::RolesControllerPatch)

  require_dependency 'my_controller'
  require 'git_hosting/patches/my_controller_patch'
  MyController.send(:include, GitHosting::Patches::MyControllerPatch)

  require_dependency 'git_hosting/patches/repository_cia_filters'
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

