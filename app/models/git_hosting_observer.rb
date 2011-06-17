class GitHostingObserver < ActiveRecord::Observer
	observe :project, :user, :gitolite_public_key, :member, :role, :repository
	
	
	def after_create(object)
		if not object.is_a?(Project)
			update_repositories(object)
		end
	end
	

	def after_save(object)    ; update_repositories(object) ; end


	def before_destroy(object)
		if object.is_a?(Repository::Git)
			if Setting.plugin_redmine_git_hosting['deleteGitRepositories'] == "true"
				GitHosting::update_repositories(object.project, true)
				%x[#{GitHosting::git_user_runner} 'rm -rf #{object.url}' ]
			end
		end
	end
	def after_destroy(object)
		if !object.is_a?(Repository::Git)
			update_repositories(object)
		end
	end


	protected
	
	def update_repositories(object)
		case object
			when Repository::Git then GitHosting::update_repositories(object.project, false)
			when User then GitHosting::update_repositories(object.projects, false) unless is_login_save?(object)
			when GitolitePublicKey then GitHosting::update_repositories(object.user.projects, false)
			when Member then GitHosting::update_repositories(object.project, false)
			when Role then GitHosting::update_repositories(object.members.map(&:project).uniq.compact, false)
		end
	end
	
	private
	
	# Test for the fingerprint of changes to the user model when the User actually logs in.
	def is_login_save?(user)
		user.changed? && user.changed.length == 2 && user.changed.include?("updated_on") && user.changed.include?("last_login_on")
	end
end
