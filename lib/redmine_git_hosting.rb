# Set up autoload of patches
def apply_patch(&block)
  ActionDispatch::Callbacks.to_prepare(&block)
end

apply_patch do
  ## Redmine dependencies
  # require project first!
  require_dependency 'project'
  require_dependency 'projects_controller'

  require_dependency 'setting'
  require_dependency 'settings_controller'

  require_dependency 'user'
  require_dependency 'users_controller'
  require_dependency 'users_helper'

  require_dependency 'repository'
  require_dependency 'repository/git'
  require_dependency 'repositories_controller'
  require_dependency 'redmine/scm/adapters/git_adapter'

  require_dependency 'member'
  require_dependency 'roles_controller'

  require_dependency 'issue'
  require_dependency 'journal'

  require_dependency 'my_controller'

  require_dependency 'sys_controller'

  ## Redmine Git Hosting Libs
  require_dependency 'redmine_gitolite/cache'
  require_dependency 'redmine_gitolite/config'
  require_dependency 'redmine_gitolite/extra_loading'
  require_dependency 'redmine_gitolite/git_hosting'
  require_dependency 'redmine_gitolite/hooks'
  require_dependency 'redmine_gitolite/log'
  require_dependency 'redmine_gitolite/recycle'

  require_dependency 'redmine_gitolite/gitolite_wrapper'
  require_dependency 'redmine_gitolite/gitolite_wrapper/admin'
  require_dependency 'redmine_gitolite/gitolite_wrapper/projects'
  require_dependency 'redmine_gitolite/gitolite_wrapper/projects_helper'
  require_dependency 'redmine_gitolite/gitolite_wrapper/repositories'
  require_dependency 'redmine_gitolite/gitolite_wrapper/repositories_helper'
  require_dependency 'redmine_gitolite/gitolite_wrapper/users'

  ## Redmine Git Hosting Patches
  require_dependency 'redmine_git_hosting/patches/project_patch'
  require_dependency 'redmine_git_hosting/patches/projects_controller_patch'

  require_dependency 'redmine_git_hosting/patches/setting_patch'
  require_dependency 'redmine_git_hosting/patches/settings_controller_patch'

  require_dependency 'redmine_git_hosting/patches/user_patch'
  require_dependency 'redmine_git_hosting/patches/users_controller_patch'
  require_dependency 'redmine_git_hosting/patches/users_helper_patch'

  require_dependency 'redmine_git_hosting/patches/repository_patch'
  require_dependency 'redmine_git_hosting/patches/repository_git_patch'
  require_dependency 'redmine_git_hosting/patches/repositories_controller_patch'
  require_dependency 'redmine_git_hosting/patches/git_adapter_patch'

  require_dependency 'redmine_git_hosting/patches/member_patch'
  require_dependency 'redmine_git_hosting/patches/roles_controller_patch'

  require_dependency 'redmine_git_hosting/patches/issue_patch'
  require_dependency 'redmine_git_hosting/patches/journal_patch'

  require_dependency 'redmine_git_hosting/patches/my_controller_patch'

  require_dependency 'redmine_git_hosting/patches/sys_controller_patch'

  ## Redmine Git Hosting Hooks
  require_dependency 'redmine_git_hosting/hooks/show_git_urls_on_project'
  require_dependency 'redmine_git_hosting/hooks/add_plugin_icon'
  require_dependency 'redmine_git_hosting/hooks/display_repository_readme'
end
