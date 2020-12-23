Redmine::AccessControl.map do |main|
  main.permission :create_gitolite_ssh_key, gitolite_public_keys: %i[index create destroy], require: :loggedin

  main.project_module :repository do |map|
    map.permission :create_repository_mirrors, repository_mirrors: %i[new create]
    map.permission :view_repository_mirrors,   repository_mirrors: %i[indexshow]
    map.permission :edit_repository_mirrors,   repository_mirrors: %i[edit update destroy]
    map.permission :push_repository_mirrors,   repository_mirrors: [:push]

    map.permission :create_repository_post_receive_urls, repository_post_receive_urls: %i[new create]
    map.permission :view_repository_post_receive_urls,   repository_post_receive_urls: %i[index show]
    map.permission :edit_repository_post_receive_urls,   repository_post_receive_urls: %i[edit update destroy]

    map.permission :create_repository_deployment_credentials, repository_deployment_credentials: %i[new create]
    map.permission :view_repository_deployment_credentials,   repository_deployment_credentials: %i[index show]
    map.permission :edit_repository_deployment_credentials,   repository_deployment_credentials: %i[edit update destroy]

    map.permission :create_repository_git_config_keys, repository_git_config_keys: %i[new create]
    map.permission :view_repository_git_config_keys,   repository_git_config_keys: %i[index show]
    map.permission :edit_repository_git_config_keys,   repository_git_config_keys: %i[edit update destroy]

    map.permission :create_repository_protected_branches, repository_protected_branches: %i[new create]
    map.permission :view_repository_protected_branches,   repository_protected_branches: %i[index show]
    map.permission :edit_repository_protected_branches,   repository_protected_branches: %i[edit update destroy]

    map.permission :view_repository_xitolite_watchers,   repositories: :show
    map.permission :add_repository_xitolite_watchers,    watchers: :create
    map.permission :delete_repository_xitolite_watchers, watchers: :destroy

    map.permission :download_git_revision, download_git_revision: :index
  end
end
