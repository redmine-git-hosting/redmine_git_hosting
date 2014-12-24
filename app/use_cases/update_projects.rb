class UpdateProjects
  unloadable

  include UseCaseBase

  attr_reader :projects
  attr_reader :message
  attr_reader :options


  def initialize(projects, opts = {})
    @projects = projects
    @message  = opts.delete(:message){ ' ' }
    @options  = opts
    super
  end


  def call
    update_projects
    super
  end


  private


    def update_projects
      RedmineGitolite::GitHosting.logger.info { message }
      RedmineGitolite::GitHosting.resync_gitolite(:update_projects, projects, options)
    end

end
