repos = Repository.find(:all)

if defined? map
	map.resources :public_keys, :controller => 'gitosis_public_keys', :path_prefix => 'my'
	for repo in repos do 
		if repo.is_a?(Repository::Git)
			grack_path=repo.url.gsub(/^.*\//, '')
			map.connect grack_path, :controller => 'grack'
		end
	end
else
	ActionController::Routing::Routes.draw do |map|
		map.resources :public_keys, :controller => 'gitosis_public_keys', :path_prefix => 'my'
		for repo in repos do 
			if repo.is_a?(Repository::Git)
				grack_path=repo.url.gsub(/^.*\//, '')
				map.connect grack_path, :controller => 'grack'
			end
		end
	end
end


