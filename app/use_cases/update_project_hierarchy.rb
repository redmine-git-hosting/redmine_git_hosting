class UpdateProjectHierarchy
  unloadable

  include UseCaseBase

  attr_reader :project
  attr_reader :message


  def initialize(project, message)
    @project = project
    @message = message
    super
  end


  def call
    update_project_hierarchy
    super
  end


  private


    def update_project_hierarchy
      projects = project.self_and_descendants

      # Only take projects that have Git repos.
      git_projects = projects.uniq.select{|p| p.gitolite_repos.any?}.map{|project| project.id}

      RedmineGitolite::GitHosting.logger.info { message }
      RedmineGitolite::GitHosting.resync_gitolite(:update_projects, git_projects)
    end

end
