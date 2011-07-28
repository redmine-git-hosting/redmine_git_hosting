projects = Project.find(:all)
for p in projects do
	GitHosting::add_route_for_project(p)
end
if defined? map
	map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
	map.connect 'githooks/post-receive', :controller => 'gitolite_hooks', :action => 'post_receive'
	map.connect 'githooks/test', :controller => 'gitolite_hooks', :action => 'test'
else
	ActionController::Routing::Routes.draw do |map|
		map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
		map.connect 'githooks/post-receive', :controller => 'gitolite_hooks', :action => 'post_receive'
		map.connect 'githooks/test', :controller => 'gitolite_hooks', :action => 'test'
	end
end

