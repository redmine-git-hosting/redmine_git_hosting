class MoveProjectHierarchy
  unloadable

  include UseCaseBase

  attr_reader :project


  def initialize(project)
    @project = project
    super
  end


  def call
    move_project_hierarchy
    super
  end


  private


    def move_project_hierarchy
      logger.info("Move repositories of project : '#{project}'")
      resync_gitolite(:move_repositories, project.id)
    end

end
