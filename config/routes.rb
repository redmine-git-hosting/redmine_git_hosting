projects = Project.find(:all)
for p in projects do
	GitHosting::add_route_for_project(p)
end
if defined? map
	map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
	map.connect 'sys/hooks/post-receive', :controller => 'gitolite_hooks', :action => 'post_receive', :conditions => {:method => :post}
else
	ActionController::Routing::Routes.draw do |map|
		map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
		map.connect 'sys/hooks/post-receive', :controller => 'gitolite_hooks', :action => 'post_receive', :conditions => {:method => :post}
	end
end

