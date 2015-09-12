module XitoliteRepositoryFinder
  extend ActiveSupport::Concern

  def find_repository
    begin
      @repository = Repository::Xitolite.find(find_repository_param)
    rescue ActiveRecord::RecordNotFound => e
      render_404
    else
      @project = @repository.project
      render_404 if @project.nil?
    end
  end

end
