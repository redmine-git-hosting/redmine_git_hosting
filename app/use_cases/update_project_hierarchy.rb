class UpdateProjectHierarchy
  unloadable

  include UseCaseBase

  attr_reader :project
  attr_reader :options


  def initialize(project, opts = {})
    @project = project
    @options = opts
    super
  end


  def call
    update_project_hierarchy
    super
  end


  private


    def update_project_hierarchy
      UpdateProjects.new(projects_to_update, options).call
    end


    def projects_to_update
      # Only take projects that have Git repos.
      project.self_and_descendants.uniq.select{|p| p.gitolite_repos.any?}.map{|project| project.id}
    end

end
