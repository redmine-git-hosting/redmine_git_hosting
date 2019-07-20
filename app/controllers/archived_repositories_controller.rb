class ArchivedRepositoriesController < RepositoriesController
  skip_before_action :authorize
  skip_before_action :find_project_repository, only: :index

  before_action :can_view_archived_projects

  def index
    @archived_projects = Project.where("status = #{Project::STATUS_ARCHIVED}").includes(:repositories)
  end

  private

  def can_view_archived_projects
    render_403 unless User.current.admin?
  end
end
