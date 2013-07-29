def install_old_routes
  ActionController::Routing::Routes.draw do |map|
    # SMART HTTP
    map.connect ":repo_path/*git_params", :prefix => (GitHostingConf.http_server_subdir rescue ""), :repo_path => /([^\/]+\/)*?[^\/]+\.git/, :controller => 'git_http'

    # Handle the public keys plugin to my/account.
    map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
    map.connect 'my/account/public_key/:public_key_id', :controller => 'my', :action => 'account'
    map.connect 'users/:id/edit/public_key/:public_key_id', :controller => 'users', :action => 'edit', :conditions => {:method => [:get]}

    # Handle hooks and mirrors
    map.connect 'githooks', :controller => 'gitolite_hooks', :action => 'stub'
    map.connect 'githooks/post-receive', :controller => 'gitolite_hooks', :action => 'post_receive'
    map.connect 'githooks/test', :controller => 'gitolite_hooks', :action => 'test'

    map.with_options :controller => 'repositories' do |repo_mapper|
      repo_mapper.with_options :controller => 'repository_mirrors' do |mirror_views|
        mirror_views.connect 'repositories/:repository_id/mirrors/new', :action => 'create', :conditions => {:method => [:get, :post]}
        mirror_views.connect 'repositories/:repository_id/mirrors/edit/:id', :action => 'edit'
        mirror_views.connect 'repositories/:repository_id/mirrors/push/:id', :action => 'push'
        mirror_views.connect 'repositories/:repository_id/mirrors/update/:id', :action => 'update', :conditions => {:method => :post}
        mirror_views.connect 'repositories/:repository_id/mirrors/delete/:id', :action => 'destroy', :conditions => {:method => [:get, :delete]}
      end

      repo_mapper.with_options :controller => 'repository_post_receive_urls' do |post_receive_views|
        post_receive_views.connect 'repositories/:repository_id/post-receive-urls/new', :action => 'create', :conditions => {:method => [:get, :post]}
        post_receive_views.connect 'repositories/:repository_id/post-receive-urls/edit/:id', :action => 'edit'
        post_receive_views.connect 'repositories/:repository_id/post-receive-urls/update/:id', :action => 'update', :conditions => {:method => :post}
        post_receive_views.connect 'repositories/:repository_id/post-receive-urls/delete/:id', :action => 'destroy', :conditions => {:method => [:get, :delete]}
      end

      repo_mapper.with_options :controller => 'deployment_credentials' do |deploy_views|
        deploy_views.connect 'repositories/:repository_id/deployment-credentials/new', :action => 'create_with_key', :conditions => {:method => [:get, :post]}
        deploy_views.connect 'repositories/:repository_id/deployment-credentials/edit/:id', :action => 'edit'
        deploy_views.connect 'repositories/:repository_id/deployment-credentials/update/:id', :action => 'update', :conditions => {:method => :post}
        deploy_views.connect 'repositories/:repository_id/deployment-credentials/delete/:id', :action => 'destroy', :conditions => {:method => [:get, :delete]}
      end
    end
  end
end

def install_new_routes
  RedmineApp::Application.routes.draw do
    # SMART HTTP
    match ':repo_path/*git_params', :prefix => (GitHostingConf.http_server_subdir rescue ""), :repo_path => /([^\/]+\/)*?[^\/]+\.git/, :to => 'git_http#index'

    # Handle the public keys plugin to my/account.
    scope "/my" do
      resources :public_keys, :controller => 'gitolite_public_keys'
    end

    match 'my/account/public_key/:public_key_id', :to => 'my#account'
    match 'users/:id/edit/public_key/:public_key_id', :to => 'users#edit', :via => [:get]

    # Handle hooks and mirrors
    match 'githooks', :to => 'gitolite_hooks#stub'
    match 'githooks/test', :to => 'gitolite_hooks#test'
    match 'githooks/post-receive', :to => 'gitolite_hooks#post_receive'

    match 'repositories/:repository_id/mirrors/new',        :to => 'repository_mirrors#create', :via => [:get, :post]
    match 'repositories/:repository_id/mirrors/edit/:id',   :to => 'repository_mirrors#edit'
    match 'repositories/:repository_id/mirrors/push/:id',   :to => 'repository_mirrors#push'
    match 'repositories/:repository_id/mirrors/update/:id', :to => 'repository_mirrors#update', :via => [:post]
    match 'repositories/:repository_id/mirrors/delete/:id', :to => 'repository_mirrors#destroy', :via => [:get, :delete]

    match 'repositories/:repository_id/post-receive-urls/new',        :to => 'repository_post_receive_urls#create', :via => [:get, :post]
    match 'repositories/:repository_id/post-receive-urls/edit/:id',   :to => 'repository_post_receive_urls#edit'
    match 'repositories/:repository_id/post-receive-urls/update/:id', :to => 'repository_post_receive_urls#update', :via => [:post]
    match 'repositories/:repository_id/post-receive-urls/delete/:id', :to => 'repository_post_receive_urls#destroy', :via => [:get, :delete]

    match 'repositories/:repository_id/deployment-credentials/new',        :to => 'deployment_credentials#create_with_key', :via => [:get, :post]
    match 'repositories/:repository_id/deployment-credentials/edit/:id',   :to => 'deployment_credentials#edit'
    match 'repositories/:repository_id/deployment-credentials/update/:id', :to => 'deployment_credentials#update', :via => [:post]
    match 'repositories/:repository_id/deployment-credentials/delete/:id', :to => 'deployment_credentials#destroy', :via => [:get, :delete]
  end
end

if Rails::VERSION::MAJOR >= 3
  install_new_routes
else
  install_old_routes
end
