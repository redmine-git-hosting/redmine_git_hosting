# Set up autoload of patches
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

## Fix Enumerable::Enumerator for Ruby 1.8.7
## https://github.com/jbox-web/redmine_git_hosting/issues/4
if RUBY_VERSION == '1.8.7'
  require 'backports'
end

def apply_patch(&block)
  if Rails::VERSION::MAJOR >= 3
    ActionDispatch::Callbacks.to_prepare(&block)
  else
    Dispatcher.to_prepare(:redmine_git_hosting_patches, &block)
  end
end

apply_patch do
  ## Redmine dependencies
  # require project first!
  require_dependency 'project'
  require_dependency 'projects_controller'

  require_dependency 'settings_controller'

  require_dependency 'user'
  require_dependency 'users_controller'
  require_dependency 'users_helper'

  require_dependency 'principal'
  require_dependency 'repository'
  require_dependency 'repository/git'
  require_dependency 'repositories_controller'
  require_dependency 'redmine/scm/adapters/git_adapter'

  require_dependency 'roles_controller'

  #----------------------------------------------------------------------

  ## Redmine Git Hosting Libs
  require_dependency 'githosting/git_hosting'
  require_dependency 'githosting/git_hosting_conf'
  require_dependency 'githosting/git_hosting_cache'
  require_dependency 'githosting/gitolite_hooks'
  require_dependency 'githosting/gitolite_recycle'
  require_dependency 'githosting/gitolite_logger'

  #----------------------------------------------------------------------

  ## Redmine Git Hosting Patches
  require_dependency 'redmine_git_hosting/patches/project_patch'
  require_dependency 'redmine_git_hosting/patches/projects_controller_patch'

  require_dependency 'redmine_git_hosting/patches/settings_controller_patch'

  require_dependency 'redmine_git_hosting/patches/user_patch'
  require_dependency 'redmine_git_hosting/patches/users_controller_patch'
  require_dependency 'redmine_git_hosting/patches/users_helper_patch'

  require_dependency 'redmine_git_hosting/patches/repository_patch'
  require_dependency 'redmine_git_hosting/patches/repository_git_patch'
  require_dependency 'redmine_git_hosting/patches/repositories_controller_patch'

  require_dependency 'redmine_git_hosting/patches/repository_cia_filters'

  require_dependency 'redmine_git_hosting/patches/roles_controller_patch'

  #----------------------------------------------------------------------

  ## Standalone mode
  # Redmine dependencies
  require_dependency 'sys_controller'
  require_dependency 'my_controller'
  require_dependency 'groups_controller'
  require_dependency 'members_controller'

  # Redmine Git Hosting Libs
  require_dependency 'githosting/gitolite_config'

  # Redmine Git Hosting Patches
  require_dependency 'redmine_git_hosting/patches/sys_controller_patch'
  require_dependency 'redmine_git_hosting/patches/my_controller_patch'
  require_dependency 'redmine_git_hosting/patches/groups_controller_patch'
  require_dependency 'redmine_git_hosting/patches/members_controller_patch'

  #----------------------------------------------------------------------

  ## Sidekiq mode
  # Redmine dependencies
  #require_dependency 'member'
  #require_dependency 'my_controller'

  # Redmine Git Hosting Libs
  #require_dependency 'githosting/gitolite_redmine'
  #require_dependency 'githosting/shell_adapter'
  #require_dependency 'githosting/shell'
  #require_dependency 'githosting/routing_constraints'

  # Redmine Git Hosting Patches
  #require_dependency 'redmine_git_hosting/patches/member_patch'
  #require_dependency 'redmine_git_hosting/patches/my_controller_patch'

  #----------------------------------------------------------------------

  ## Put git_adapter_patch last (make sure that git_cmd stays patched!)
  require_dependency 'redmine_git_hosting/patches/git_adapter_patch'

  #----------------------------------------------------------------------

  ## Redmine Git Hosting Hooks
  require_dependency 'redmine_git_hosting/hooks/git_project_show_hook'
  require_dependency 'redmine_git_hosting/hooks/git_repo_url_hook'
  require_dependency 'redmine_git_hosting/hooks/add_plugin_icon'
end
