class GitHostingObserver < ActiveRecord::Observer
	observe :project, :user, :gitolite_public_key, :member, :role, :repository

	@@updating_active = true
	@@cached_project_updates = []

	def self.set_update_active(is_active)
		@@updating_active = is_active
		if is_active
			if @@cached_project_updates.length > 0
				@@cached_project_updates = @@cached_project_updates.flatten.uniq.compact
				GitHosting::update_repositories(@@cached_project_updates, false)
			end
		end
		@@cached_project_updates = []
	end


	def before_destroy(object)
		if object.is_a?(Repository::Git)
			if Setting.plugin_redmine_git_hosting['deleteGitRepositories'] == "true"
				GitHosting::update_repositories(object.project, true)
				%x[#{GitHosting::git_user_runner} 'rm -rf #{object.url}' ]
			end
			GitHosting::clear_cache_for_project(object.project)
		end
	end


	def after_create(object)
		if not object.is_a?(Project)
			update_repositories(object)
		end
	end


	def before_save(object)
		if object.is_a?(Repository::Git)
			GitHosting.logger.debug "On GitHostingObserver.before_save for Repository::Git"
			object.extra = GitRepositoryExtra.new
		end
	end


	def after_save(object)
		update_repositories(object)
	end


	def after_destroy(object)
		if !object.is_a?(Repository::Git)
			update_repositories(object)
		end
	end


	protected


	def update_repositories(object)

		projects = []
		case object
			when Repository::Git then projects.push(object.project)
			when User then projects = object.projects unless is_login_save?(object)
			when GitolitePublicKey then projects = object.user.projects
			when Member then projects.push(object.project)
			when Role then projects = object.members.map(&:project).flatten.uniq.compact
		end
		if(projects.length > 0)
			if (@@updating_active)
				GitHosting::update_repositories(projects, false)
			else
				@@cached_project_updates.concat(projects)
			end
		end
	end


	# Test for the fingerprint of changes to the user model when the User actually logs in.
	def is_login_save?(user)
		user.changed? && user.changed.length == 2 && user.changed.include?("updated_on") && user.changed.include?("last_login_on")
	end
end
