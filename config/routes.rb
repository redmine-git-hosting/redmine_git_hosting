Rails.application.routes.draw do
  # Handle the public keys plugin to my/account.
  scope 'my' do
    resources :public_keys, controller: 'gitolite_public_keys'
  end

  # Don't create routes for repositories resources with only: []
  # to not override Redmine's routes.
  resources :repositories, only: [] do
    member do
      get 'download_revision', to: 'download_git_revision#index', as: 'download_git_revision'
    end

    resource :git_extras, controller: 'repository_git_extras', only: [:update] do
      match 'sort_urls', via: %i[get post]
      member do
        match 'move', via: %i[get post]
      end
    end

    resources :post_receive_urls,      controller: 'repository_post_receive_urls'
    resources :deployment_credentials, controller: 'repository_deployment_credentials'
    resources :git_config_keys,        controller: 'repository_git_config_keys'

    resources :mirrors, controller: 'repository_mirrors' do
      member { get :push }
    end

    resources :protected_branches, controller: 'repository_protected_branches' do
      member     { get :clone }
      collection { post :sort }
    end
  end

  # Enable Redirector for Go Lang repositories
  get 'go/:repo_path', repo_path: %r{([^/]+/)*?[^/]+}, to: 'go_redirector#index'

  get 'admin/settings/plugin/:id/authors', to: 'settings#authors', as: 'plugin_authors'
  get 'admin/settings/plugin/:id/install_gitolite_hooks', to: 'settings#install_gitolite_hooks', as: 'install_gitolite_hooks'

  # Enable SmartHTTP Grack support
  mount Grack::Bundle.new({}),
        at: RedmineGitHosting::Config.http_server_subdir,
        constraints: ->(request) { %r{[-/\w.]+\.git/}.match(request.path_info) },
        via: %i[get post]

  # Post Receive Hooks
  mount Hrack::Bundle.new({}), at: 'githooks/post-receive/:type/:projectid', via: [:post]
end
