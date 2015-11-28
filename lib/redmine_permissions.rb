Redmine::AccessControl.map do |main|
  main.permission :create_gitolite_ssh_key, gitolite_public_keys: [:index, :create, :destroy], require: :loggedin

  main.project_module :repository do |map|
    map.permission :create_repository_mirrors, repository_mirrors: [:new, :create]
    map.permission :view_repository_mirrors,   repository_mirrors: [:index, :show]
    map.permission :edit_repository_mirrors,   repository_mirrors: [:edit, :update, :destroy]
    map.permission :push_repository_mirrors,   repository_mirrors: [:push]

    map.permission :create_repository_post_receive_urls, repository_post_receive_urls: [:new, :create]
    map.permission :view_repository_post_receive_urls,   repository_post_receive_urls: [:index, :show]
    map.permission :edit_repository_post_receive_urls,   repository_post_receive_urls: [:edit, :update, :destroy]

    map.permission :create_repository_deployment_credentials, repository_deployment_credentials: [:new, :create]
    map.permission :view_repository_deployment_credentials,   repository_deployment_credentials: [:index, :show]
    map.permission :edit_repository_deployment_credentials,   repository_deployment_credentials: [:edit, :update, :destroy]

    map.permission :create_repository_git_config_keys, repository_git_config_keys: [:new, :create]
    map.permission :view_repository_git_config_keys,   repository_git_config_keys: [:index, :show]
    map.permission :edit_repository_git_config_keys,   repository_git_config_keys: [:edit, :update, :destroy]

    map.permission :create_repository_protected_branches, repository_protected_branches: [:new, :create]
    map.permission :view_repository_protected_branches,   repository_protected_branches: [:index, :show]
    map.permission :edit_repository_protected_branches,   repository_protected_branches: [:edit, :update, :destroy]

    map.permission :view_repository_xitolite_watchers,   repositories: :show
    map.permission :add_repository_xitolite_watchers,    watchers: :create
    map.permission :delete_repository_xitolite_watchers, watchers: :destroy

    map.permission :download_git_revision, download_git_revision: :index
  end
end
