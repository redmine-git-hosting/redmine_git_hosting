projects = Project.find(:all)

if defined? map
	map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
	for p in projects do
	       repo = p.repository	
		if repo.is_a?(Repository::Git)
			repo_path=repo.url.gsub(/^.*\//, '')
			map.connect repo_path,                  :controller => 'git_http', :p1 => '', :p2 =>'', :p3 =>'', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
			map.connect repo_path + "/:p1",         :controller => 'git_http', :p2 => '', :p3 =>'', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
			map.connect repo_path + "/:p1/:p2",     :controller => 'git_http', :p3 => '', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
			map.connect repo_path + "/:p1/:p2/:p3", :controller => 'git_http', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
		end
	end
else
	ActionController::Routing::Routes.draw do |map|
		map.resources :public_keys, :controller => 'gitolite_public_keys', :path_prefix => 'my'
		for p in projects do 
			repo = p.repository
			if repo.is_a?(Repository::Git)
				repo_path=repo.url.gsub(/^.*\//, '')
				map.connect repo_path,                  :controller => 'git_http', :p1 => '', :p2 =>'', :p3 =>'', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
				map.connect repo_path + "/:p1",         :controller => 'git_http', :p2 => '', :p3 =>'', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
				map.connect repo_path + "/:p1/:p2",     :controller => 'git_http', :p3 => '', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
				map.connect repo_path + "/:p1/:p2/:p3", :controller => 'git_http', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
			end
		end
	end
end

