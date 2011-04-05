#git_repos = Repository.where(:scm_name=>"Git")
repos = Repository.find(:all)


if defined? map
	map.resources :public_keys, :controller => 'gitosis_public_keys', :path_prefix => 'my'
	for repo in repos do 
		if repo.is_a?(Repository::Git)
			grack_path=repo.url.gsub(/^.*\//, '')
			map.connect grack_path,                  :controller => 'grack', :p1 => '', :p2 =>'', :p3 =>''
			map.connect grack_path + "/:p1",         :controller => 'grack', :p2 => '', :p3 =>''
			map.connect grack_path + "/:p1/:p2",     :controller => 'grack', :p3 => ''
			map.connect grack_path + "/:p1/:p2/:p3", :controller => 'grack'
		end
	end
else
	ActionController::Routing::Routes.draw do |map|
		map.resources :public_keys, :controller => 'gitosis_public_keys', :path_prefix => 'my'
		for repo in repos do 
			if repo.is_a?(Repository::Git)
				grack_path=repo.url.gsub(/^.*\//, '')
				map.connect grack_path,                  :controller => 'grack', :p1 => '', :p2 =>'', :p3 =>''
				map.connect grack_path + "/:p1",         :controller => 'grack', :p2 => '', :p3 =>''
				map.connect grack_path + "/:p1/:p2",     :controller => 'grack', :p3 => ''
				map.connect grack_path + "/:p1/:p2/:p3", :controller => 'grack'
			end
		end
	end
end

