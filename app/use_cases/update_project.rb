class UpdateProject
  unloadable

  attr_reader :project
  attr_reader :options


  def initialize(project, opts = {})
    @project = project
    @options = opts
  end


  def call
    update_project
  end


  private


    def update_project
      # Adjust daemon status
      disable_git_daemon_if_not_public
      resync
    end


    def disable_git_daemon_if_not_public
      # Go through all gitolite repos and disable Git daemon if necessary
      project.gitolite_repos.each do |repository|
        if repository.extra[:git_daemon] && !project.is_public
          repository.extra[:git_daemon] = false
          repository.extra.save
        end
      end
    end


    def resync
      GitoliteAccessor.update_projects([project.id], options)
    end

end
