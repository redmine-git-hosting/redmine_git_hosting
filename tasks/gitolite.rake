namespace :gitolite do
	desc "update gitolite repositories"
	task :update_repositories => [:environment] do
		projects = Project.active
		puts "Updating repositories for projects #{projects.join(' ')}"
		GitHosting.update_repositories(projects, false)
	end
	desc "fetch commits from gitolite repositories"
	task :fetch_changes => [:environment] do
		Repository.fetch_changesets
	end

end
