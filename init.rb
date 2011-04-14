require 'redmine'
require_dependency 'principal'
require_dependency 'user'

require_dependency 'gitolite'
require_dependency 'gitolite/patches/repositories_controller_patch'
require_dependency 'gitolite/patches/repositories_helper_patch'
require_dependency 'gitolite/patches/git_adapter_patch'

Redmine::Plugin.register :redmine_gitolite do
	name 'Redmine Gitolite plugin'
	author 'Christian Käser, Zsolt Parragi, Yunsang Choi, Joshua Hogendorn, Jan Schulz-Hofen and others'
	description 'Enables Redmine to update a gitolite server.'
	version '0.1.0'
	settings :default => {
		'gitUser' => 'git',
		'gitServer' => 'localhost',
		'gitoliteIdentityFile' => '/srv/projects/redmine/miner/.ssh/gitolite_admin_id_rsa',
		'gitUserIdentityFile'  => '/srv/projects/redmine/miner/.ssh/git_user_id_rsa',
		'allProjectsUseGit' => 'false',
		
		#these are somewhat deprecated, will be removed in the future in favor of the settings above 
		'gitRepositoryBasePath' => '/srv/projects/git/repositories/',
		'gitoliteUrl' => 'git@localhost:gitolite-admin.git',
		'readOnlyBaseUrls' => "",
		'developerBaseUrls' => ""
		}, 
		:partial => 'redmine_gitolite'
end

# initialize hook
class GitolitePublicKeyHook < Redmine::Hook::ViewListener
	render_on :view_my_account_contextual, :inline => "| <%= link_to(l(:label_public_keys), public_keys_path) %>" 
end

class GitoliteProjectShowHook < Redmine::Hook::ViewListener
	render_on :view_projects_show_left, :partial => 'redmine_gitolite'
end

# initialize association from user -> public keys
User.send(:has_many, :gitolite_public_keys, :dependent => :destroy)

#initialize association from repository -> git_repo_hosting_options
Repository.send(:has_one, :git_repo_hosting_options, :dependent => :destroy)

# initialize observer
ActiveRecord::Base.observers = ActiveRecord::Base.observers << GitoliteObserver
