class GitHostingObserver < ActiveRecord::Observer
	observe :project, :user, :gitolite_public_key, :member, :role, :repository
	
	
	def after_create(object)
		if object.is_a?(Project)
			users = object.member_principals.map(&:user).compact.uniq
			if users.length == 0
				membership = Member.new(
					:principal=>User.current,
					:project_id=>object.id,
					:role_ids=>[3]
					)
				membership.save
			end
			if Setting.plugin_redmine_git_hosting['allProjectsUseGit'] == "true"
				repo = Repository::Git.new
				repo_name= object.parent ? File.join(object.parent.identifier,object.identifier) : object.identifier
				repo.url = repo.root_url = File.join(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'], "#{repo_name}.git")
				object.repository = repo
			end
		else
			update_repositories(object)
		end
	end
	

	def after_save(object)    ; update_repositories(object) ; end
	def after_destroy(object) ; update_repositories(object) ; end
	
	protected
	
	def update_repositories(object)
		case object
			when Repository then GitHosting::update_repositories(object.project)
			when User then GitHosting::update_repositories(object.projects) unless is_login_save?(object)
			when GitolitePublicKey then GitHosting::update_repositories(object.user.projects)
			when Member then GitHosting::update_repositories(object.project)
			when Role then GitHosting::update_repositories(object.members.map(&:project).uniq.compact)
		end
	end
	
	private
	
	# Test for the fingerprint of changes to the user model when the User actually logs in.
	def is_login_save?(user)
		user.changed? && user.changed.length == 2 && user.changed.include?("updated_on") && user.changed.include?("last_login_on")
	end
end
