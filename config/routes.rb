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
		project_mapper.with_options :conditions => {:method => :get} do |project_views|
			project_views.connect 'projects/:project_id/settings/repository/mirrors/new', :controller => 'repository_mirrors', :action => 'create'
			project_views.connect 'projects/:project_id/settings/repository/mirrors/edit/:id', :controller => 'repository_mirrors', :action => 'edit'
			project_views.connect 'projects/:project_id/settings/repository/mirrors/delete/:id', :controller => 'repository_mirrors', :action => 'delete'
		end
	end
else
	ActionController::Routing::Routes.draw do |map|
		map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
		map.connect 'githooks', :controller => 'gitolite_hooks', :action => 'stub'
		map.connect 'githooks/post-receive', :controller => 'gitolite_hooks', :action => 'post_receive'
		map.connect 'githooks/test', :controller => 'gitolite_hooks', :action => 'test'
		map.with_options :controller => 'projects' do |project_mapper|
			project_mapper.with_options :conditions => {:method => :get} do |project_views|
				project_views.connect 'projects/:project_id/settings/repository/mirrors/new', :controller => 'repository_mirrors', :action => 'create'
				project_views.connect 'projects/:project_id/settings/repository/mirrors/edit/:id', :controller => 'repository_mirrors', :action => 'edit'
				project_views.connect 'projects/:project_id/settings/repository/mirrors/delete/:id', :controller => 'repository_mirrors', :action => 'delete'
			end
		end
	end
end

