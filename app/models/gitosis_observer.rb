class GitosisObserver < ActiveRecord::Observer
  observe :project, :user, :gitosis_public_key, :member, :role, :repository
  
  
#  def before_create(object)
#    if object.is_a?(Project)
#      repo = Repository::Git.new
#      repo.url = repo.root_url = File.join(Gitosis::GITOSIS_BASE_PATH,"#{object.identifier}.git")
#      object.repository = repo
#    end
#  end
  
  def after_save(object) ; update_repositories(object) ; end
  def after_destroy(object) ; update_repositories(object) ; end
  
  protected
  
  def update_repositories(object)
    case object
      when Project then Gitosis::update_repositories(object)
      when Repository then Gitosis::update_repositories(object.project)
      when User then Gitosis::update_repositories(object.projects)
      when GitosisPublicKey then Gitosis::update_repositories(object.user.projects)
      when Member then Gitosis::update_repositories(object.project)
      when Role then Gitosis::update_repositories(object.members.map(&:project).uniq.compact)
    end
  end
  
end
