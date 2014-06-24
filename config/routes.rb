RedmineApp::Application.routes.draw do
  # Handle the public keys plugin to my/account.
  scope "/my" do
    resources :public_keys, :controller => 'gitolite_public_keys'
  end

  match 'repositories/:repository_id/mirrors/:id/push', :to => 'repository_mirrors#push', :via => [:get], :as => 'push_to_mirror'

  match 'repositories/:repository_id/protected_branches/:id/clone', :to => 'repository_protected_branches#clone', :via => [:get], :as => 'clone_repository_protected_branch'

  match 'repositories/:repository_id/download_revision/:rev', :to  => 'download_git_revision#index',
                                                              :via => [:get],
                                                              :as  => 'download_git_revision'

  resources :repositories do
    constraints(repository_id: /\d+/, id: /\d+/) do
      resources :mirrors,                controller: 'repository_mirrors'
      resources :post_receive_urls,      controller: 'repository_post_receive_urls'
      resources :deployment_credentials, controller: 'repository_deployment_credentials'
      resources :git_notifications,      controller: 'repository_git_notifications'
      resources :git_config_keys,        controller: 'repository_git_config_keys'
      resources :protected_branches,     controller: 'repository_protected_branches' do
        collection { post :sort }
      end
    end
  end

  # SMART HTTP
  match ':repo_path/*git_params', :prefix => RedmineGitolite::Config.get_setting(:http_server_subdir), :repo_path => /([^\/]+\/)*?[^\/]+\.git/, :to => 'smart_http#index'

  # POST RECEIVE
  match 'githooks/post-receive/:type/:projectid',  :to => 'gitolite_hooks#post_receive', :via => [:post]

  # ARCHIVED REPOSITORIES
  get 'archived_projects/index',                                                :to => 'archived_repositories#index'
  get 'archived_projects/:id/repository/:repository_id/statistics',             :to => 'archived_repositories#stats'
  get 'archived_projects/:id/repository/:repository_id/graph',                  :to => 'archived_repositories#graph'
  get 'archived_projects/:id/repository/:repository_id/changes(/*path(.:ext))', :to => 'archived_repositories#changes'
  get 'archived_projects/:id/repository/:repository_id/revisions/:rev',         :to => 'archived_repositories#revision'
  get 'archived_projects/:id/repository/:repository_id/revision',               :to => 'archived_repositories#revision'
  get 'archived_projects/:id/repository/:repository_id/revisions',              :to => 'archived_repositories#revisions'
  get 'archived_projects/:id/repository/:repository_id/revisions/:rev/:action(/*path(.:ext))',
      :controller => 'archived_repositories',
      :format => false,
      :constraints => {
            :action => /(browse|show|entry|raw|annotate|diff)/,
            :rev    => /[a-z0-9\.\-_]+/
          }

  get 'archived_projects/:id/repository/statistics',               :to => 'archived_repositories#stats'
  get 'archived_projects/:id/repository/graph',                    :to => 'archived_repositories#graph'
  get 'archived_projects/:id/repository/changes(/*path(.:ext))',   :to => 'archived_repositories#changes'
  get 'archived_projects/:id/repository/revisions',                :to => 'archived_repositories#revisions'
  get 'archived_projects/:id/repository/revisions/:rev',           :to => 'archived_repositories#revision'
  get 'archived_projects/:id/repository/revision',                 :to => 'archived_repositories#revision'
  get 'archived_projects/:id/repository/revisions/:rev/:action(/*path(.:ext))',
      :controller => 'archived_repositories',
      :format => false,
      :constraints => {
            :action => /(browse|show|entry|raw|annotate|diff)/,
            :rev    => /[a-z0-9\.\-_]+/
          }
  get 'archived_projects/:id/repository/:repository_id/:action(/*path(.:ext))',
      :controller => 'archived_repositories',
      :action => /(browse|show|entry|raw|changes|annotate|diff)/

  get 'archived_projects/:id/repository/:action(/*path(.:ext))',
      :controller => 'archived_repositories',
      :action => /(browse|show|entry|raw|changes|annotate|diff)/

  get 'archived_projects/:id/repository/:repository_id', :to => 'archived_repositories#show', :path => nil
  get 'archived_projects/:id/repository',                :to => 'archived_repositories#show', :path => nil

end
