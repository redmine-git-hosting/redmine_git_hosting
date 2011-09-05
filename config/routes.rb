projects = Project.find(:all)
for p in projects do
	GitHosting::add_route_for_project(p)
end
if defined? map
	map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
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
	end
else
	ActionController::Routing::Routes.draw do |map|
		map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
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
		end
	end
end

