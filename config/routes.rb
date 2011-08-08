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
			 project_views.connect 'projects/:id/settings/repository-mirrors', :controller => 'repository_mirrors', :action => 'settings'
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
				project_views.connect 'projects/:id/settings/repository-mirrors', :controller => 'repository_mirrors', :action => 'settings'
			end
		end
	end
end

