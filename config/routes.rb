projects = Project.find(:all)
for p in projects do
	GitHosting::add_route_for_project(p)
end
if defined? map
	map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
	map.connect 'githooks', :controller => 'gitolite_hooks', :action => 'stub'
	map.connect 'githooks/post-receive', :controller => 'gitolite_hooks', :action => 'post_receive'
else
	ActionController::Routing::Routes.draw do |map|
		map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
		map.connect 'githooks', :controller => 'gitolite_hooks', :action => 'stub'
		map.connect 'githooks/post-receive', :controller => 'gitolite_hooks', :action => 'post_receive'
	end
end

