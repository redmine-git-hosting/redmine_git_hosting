def install_redmine_git_hosting_routes(map)
    # URL for items of type httpServer/XXX.git.	 Some versions of rails has problems with multiple regex expressions, so avoid...
    # Note that 'http_server_subdir' is either empty (default case) or ends in '/'.
    map.connect ":project_path/*path",
    :prefix => Setting.plugin_redmine_git_hosting['httpServerSubdir'], :project_path => /([^\/]+\/)*?[^\/]+\.git/, :controller => 'git_http'

    # Handle the public keys plugin to my/account.
    map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
    map.connect 'my/account/public_key/:public_key_id', :controller => 'my', :action => 'account'
    map.connect 'users/:id/edit/public_key/:public_key_id', :controller => 'users', :action => 'edit', :conditions => {:method => [:get]}

    # Handle hooks and mirrors
    map.connect 'githooks', :controller => 'gitolite_hooks', :action => 'stub'
    map.connect 'githooks/post-receive', :controller => 'gitolite_hooks', :action => 'post_receive'
    map.connect 'githooks/test', :controller => 'gitolite_hooks', :action => 'test'
    map.with_options :controller => 'projects' do |project_mapper|
	project_mapper.with_options :controller => 'repository_mirrors' do |project_views|
	    project_views.connect 'projects/:project_id/settings/repository/mirrors/new', :action => 'create', :conditions => {:method => [:get, :post]}
	    project_views.connect 'projects/:project_id/settings/repository/mirrors/edit/:id', :action => 'edit'
	    project_views.connect 'projects/:project_id/settings/repository/mirrors/push/:id', :action => 'push'
	    project_views.connect 'projects/:project_id/settings/repository/mirrors/update/:id', :action => 'update', :conditions => {:method => :post}
	    project_views.connect 'projects/:project_id/settings/repository/mirrors/delete/:id', :action => 'destroy', :conditions => {:method => [:get, :delete]}
	end
	project_mapper.with_options :controller => 'repository_post_receive_urls' do |project_views|
	    project_views.connect 'projects/:project_id/settings/repository/post-receive-urls/new', :action => 'create', :conditions => {:method => [:get, :post]}
	    project_views.connect 'projects/:project_id/settings/repository/post-receive-urls/edit/:id', :action => 'edit'
	    project_views.connect 'projects/:project_id/settings/repository/post-receive-urls/update/:id', :action => 'update', :conditions => {:method => :post}
	    project_views.connect 'projects/:project_id/settings/repository/post-receive-urls/delete/:id', :action => 'destroy', :conditions => {:method => [:get, :delete]}
	end
    end
end

if defined? map
    install_redmine_git_hosting_routes(map)
else
    ActionController::Routing::Routes.draw do |map|
	install_redmine_git_hosting_routes(map)
    end
end
