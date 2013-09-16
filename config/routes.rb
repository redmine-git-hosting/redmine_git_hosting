def install_old_routes
  ActionController::Routing::Routes.draw do |map|
    # Handle the public keys plugin to my/account.
    map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'

    map.with_options :controller => 'repositories' do |repo_mapper|
      repo_mapper.with_options :controller => 'repository_mirrors' do |mirror_views|
        mirror_views.connect 'repositories/:repository_id/mirrors/new',        :action => 'create',  :conditions => {:method => [:get, :post]}
        mirror_views.connect 'repositories/:repository_id/mirrors/edit/:id',   :action => 'edit',    :conditions => {:method => :get}
        mirror_views.connect 'repositories/:repository_id/mirrors/push/:id',   :action => 'push',    :conditions => {:method => :get}
        mirror_views.connect 'repositories/:repository_id/mirrors/update/:id', :action => 'update',  :conditions => {:method => :put}
        mirror_views.connect 'repositories/:repository_id/mirrors/delete/:id', :action => 'destroy', :conditions => {:method => [:get, :delete]}
      end

      repo_mapper.with_options :controller => 'repository_post_receive_urls' do |post_receive_views|
        post_receive_views.connect 'repositories/:repository_id/post-receive-urls/new',        :action => 'create',  :conditions => {:method => [:get, :post]}
        post_receive_views.connect 'repositories/:repository_id/post-receive-urls/edit/:id',   :action => 'edit',    :conditions => {:method => :get}
        post_receive_views.connect 'repositories/:repository_id/post-receive-urls/update/:id', :action => 'update',  :conditions => {:method => :put}
        post_receive_views.connect 'repositories/:repository_id/post-receive-urls/delete/:id', :action => 'destroy', :conditions => {:method => [:get, :delete]}
      end

      repo_mapper.with_options :controller => 'repository_deployment_credentials' do |deploy_views|
        deploy_views.connect 'repositories/:repository_id/deployment-credentials/new',        :action => 'create_with_key', :conditions => {:method => [:get, :post]}
        deploy_views.connect 'repositories/:repository_id/deployment-credentials/edit/:id',   :action => 'edit',            :conditions => {:method => :get}
        deploy_views.connect 'repositories/:repository_id/deployment-credentials/update/:id', :action => 'update',          :conditions => {:method => :put}
        deploy_views.connect 'repositories/:repository_id/deployment-credentials/delete/:id', :action => 'destroy',         :conditions => {:method => [:get, :delete]}
      end

      repo_mapper.with_options :controller => 'repository_git_notifications' do |git_notify_views|
        git_notify_views.connect 'repositories/:repository_id/git-notifications/new',        :action => 'create',   :conditions => {:method => [:get, :post]}
        git_notify_views.connect 'repositories/:repository_id/git-notifications/edit/:id',   :action => 'edit',     :conditions => {:method => :get}
        git_notify_views.connect 'repositories/:repository_id/git-notifications/update/:id', :action => 'update',   :conditions => {:method => :put}
        git_notify_views.connect 'repositories/:repository_id/git-notifications/delete/:id', :action => 'destroy',  :conditions => {:method => [:get, :delete]}
      end
    end

    # NOTIFY CIA
    map.connect 'githooks',                 :controller => 'gitolite_hooks', :action => 'stub'
    map.connect 'githooks/notify-cia-test', :controller => 'gitolite_hooks', :action => 'notify_cia_test', :conditions => {:method => :post}

    # SMART HTTP
    map.connect ":repo_path/*git_params", :prefix => GitHostingConf.http_server_subdir, :repo_path => /([^\/]+\/)*?[^\/]+\.git/, :controller => 'smart_http', :action => 'index'

    # POST RECEIVE
    map.connect 'githooks/post-receive', :controller => 'gitolite_hooks', :action => 'post_receive'

    # SIDEKIQ
    #~ mount Sidekiq::Web, :at => '/sidekiq', :as => 'sidekiq', :constraints => GitHosting::AdminConstraint.new
  end
end

def install_new_routes
  RedmineApp::Application.routes.draw do
    # Handle the public keys plugin to my/account.
    scope "/my" do
      resources :public_keys, :controller => 'gitolite_public_keys'
    end

    match 'repositories/:repository_id/mirrors/new',        :to => 'repository_mirrors#create',  :via => [:get, :post]
    match 'repositories/:repository_id/mirrors/edit/:id',   :to => 'repository_mirrors#edit',    :via => [:get]
    match 'repositories/:repository_id/mirrors/push/:id',   :to => 'repository_mirrors#push',    :via => [:get]
    match 'repositories/:repository_id/mirrors/update/:id', :to => 'repository_mirrors#update',  :via => [:put]
    match 'repositories/:repository_id/mirrors/delete/:id', :to => 'repository_mirrors#destroy', :via => [:get, :delete]

    match 'repositories/:repository_id/post-receive-urls/new',        :to => 'repository_post_receive_urls#create',  :via => [:get, :post]
    match 'repositories/:repository_id/post-receive-urls/edit/:id',   :to => 'repository_post_receive_urls#edit',    :via => [:get]
    match 'repositories/:repository_id/post-receive-urls/update/:id', :to => 'repository_post_receive_urls#update',  :via => [:put]
    match 'repositories/:repository_id/post-receive-urls/delete/:id', :to => 'repository_post_receive_urls#destroy', :via => [:get, :delete]

    match 'repositories/:repository_id/deployment-credentials/new',        :to => 'repository_deployment_credentials#create_with_key', :via => [:get, :post]
    match 'repositories/:repository_id/deployment-credentials/edit/:id',   :to => 'repository_deployment_credentials#edit',            :via => [:get]
    match 'repositories/:repository_id/deployment-credentials/update/:id', :to => 'repository_deployment_credentials#update',          :via => [:put]
    match 'repositories/:repository_id/deployment-credentials/delete/:id', :to => 'repository_deployment_credentials#destroy',         :via => [:get, :delete]

    match 'repositories/:repository_id/git-notifications/new',        :to => 'repository_git_notifications#create',  :via => [:get, :post]
    match 'repositories/:repository_id/git-notifications/edit/:id',   :to => 'repository_git_notifications#edit',    :via => [:get]
    match 'repositories/:repository_id/git_notifications/update/:id', :to => 'repository_git_notifications#update',  :via => [:put]
    match 'repositories/:repository_id/git_notifications/delete/:id', :to => 'repository_git_notifications#destroy', :via => [:get, :delete]

    # NOTIFY CIA
    match 'githooks',                 :to => 'gitolite_hooks#stub'
    match 'githooks/notify-cia-test', :to => 'gitolite_hooks#notify_cia_test', :via => [:post]

    # SMART HTTP
    match ':repo_path/*git_params', :prefix => GitHostingConf.http_server_subdir, :repo_path => /([^\/]+\/)*?[^\/]+\.git/, :to => 'smart_http#index'

    # POST RECEIVE
    match 'githooks/post-receive', :to => 'gitolite_hooks#post_receive'

    # SIDEKIQ
    #~ mount Sidekiq::Web, :at => '/sidekiq', :as => 'sidekiq', :constraints => GitHosting::AdminConstraint.new
  end
end

if Rails::VERSION::MAJOR >= 3
  install_new_routes
else
  install_old_routes
end
