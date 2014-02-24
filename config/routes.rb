RedmineApp::Application.routes.draw do
  # Handle the public keys plugin to my/account.
  scope "/my" do
    resources :public_keys, :controller => 'gitolite_public_keys'
  end

  match 'repositories/:repository_id/mirrors/:id/push', :to => 'repository_mirrors#push', :via => [:get], :as => 'push_to_mirror'

  match 'repositories/:repository_id/download_revision/:rev', :to  => 'download_git_revision#index',
                                                              :via => [:post],
                                                              :as  => 'download_git_revision'

  resources :repositories do
    constraints(repository_id: /\d+/, id: /\d+/) do
      resources :mirrors,                controller: 'repository_mirrors'
      resources :post_receive_urls,      controller: 'repository_post_receive_urls'
      resources :deployment_credentials, controller: 'repository_deployment_credentials'
      resources :git_notifications,      controller: 'repository_git_notifications'
    end
  end

  # SMART HTTP
  match ':repo_path/*git_params', :prefix => RedmineGitolite::Config.http_server_subdir, :repo_path => /([^\/]+\/)*?[^\/]+\.git/, :to => 'smart_http#index'

  # POST RECEIVE
  match 'githooks/post-receive', :to => 'gitolite_hooks#post_receive'
end
