#
# WARNING: Tasks in this file have been deprecated.  See redmine_git_hosting.rake.
#
# There are two tasks here of interest: gitolite:update_repositories and gitolite:fetch_changesets.
# The second includes the first (since fetching of changesets causes updating of gitolite config).
#
# As of the most recent release, either of these will complete resynchronize the gitolite configuration
# and can thus be used to recover from errors that might have been introduced by sychronization errors.
#
# Specifically:
#
# 1) Resynchronize gitolite configuration (fix keys directory and configuration).  Also, expire
#    repositories in the recycle_bin if time.
#
# rake gitolite:update_repositories RAILS_ENV=xxx
#
# 2) Fetch all changesets for repositories and then rescynronize gitolite configuration (as in #1)
#
# rake gitolite:fetch_changes RAILS_ENV=xxx
#
namespace :gitolite do
	desc "Update/repair gitolite configuration"
	task :update_repositories => [:environment] do
		puts "WARNING: This task deprecated.  Use 'rake redmine_git_hosting:update_repositories' instead."
		Rake::Task["redmine_git_hosting:update_repositories"].invoke
	end
	desc "Fetch commits from gitolite repositories/update gitolite configuration"
	task :fetch_changes => [:environment] do
		puts "WARNING: This task deprecated.  Use 'rake redmine_git_hosting:fetch_changesets' instead."
		Rake::Task["redmine_git_hosting:fetch_changesets"].invoke
	end

end
