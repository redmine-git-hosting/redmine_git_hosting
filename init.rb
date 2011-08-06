require 'redmine'
require_dependency 'principal'
require_dependency 'user'

require_dependency 'git_hosting'
require_dependency 'git_hosting/hooks/git_adapter_hooks'
require_dependency 'git_hosting/patches/projects_controller_patch'
require_dependency 'git_hosting/patches/repositories_controller_patch'
require_dependency 'git_hosting/patches/groups_controller_patch'
require_dependency 'git_hosting/patches/repositories_helper_patch'
require_dependency 'git_hosting/patches/repository_patch'
require_dependency 'git_hosting/patches/git_adapter_patch'
require_dependency 'git_hosting/patches/git_hosting_settings_patch'

Redmine::Plugin.register :redmine_git_hosting do
	name 'Redmine Git Hosting Plugin'
	author 'Eric Bishop, Christian Käser, Zsolt Parragi, Yunsang Choi, Joshua Hogendorn, Jan Schulz-Hofen and others'
	description 'Enables Redmine / ChiliProject to control hosting of git repositories'
	version '0.3.0'
	url 'https://github.com/ericpaulbishop/redmine_git_hosting'
	settings :default => {
		'allProjectsUseGit' => 'false',
		'gitServer' => 'localhost',
		'httpServer' => 'localhost',
		'gitUser' => 'git',
		'gitoliteIdentityFile' => RAILS_ROOT + '/.ssh/gitolite_admin_id_rsa',
		'gitRepositoryBasePath' => 'repositories/',
		'deleteGitRepositories' => 'false',
		'gitRepositoriesShowUrl' => 'true',
		'loggingEnabled' => 'false',
		'gitCacheMaxTime' => '-1',
		'gitCacheMaxElements' => '100',
		'gitCacheMaxSize' => '16',
		'gitHooksDebug' => 'false',
		'gitHooksCurlIgnore' => 'false',
		'gitHooksUrl' => ''
		},
		:partial => 'redmine_git_hosting'
end

# initialize hooks
class GitProjectShowHook < Redmine::Hook::ViewListener
	render_on :view_projects_show_left, :partial => 'git_urls'
end

class GitRepoUrlHook < Redmine::Hook::ViewListener
	render_on :view_repositories_show_contextual, :partial => 'git_urls'
end


# initialize association from user -> public keys
User.send(:has_many, :gitolite_public_keys, :dependent => :destroy)

# initialize observer
ActiveRecord::Base.observers = ActiveRecord::Base.observers << GitHostingObserver
