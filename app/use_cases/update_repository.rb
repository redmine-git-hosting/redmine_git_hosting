class UpdateRepository
  unloadable

  include UseCaseBase

  attr_reader :repository
  attr_reader :params


  def initialize(repository, params)
    @repository = repository
    @params     = params
    super
  end


  def call
    update_repository
    super
  end


  private


    def update_repository
      params[:extra][:git_daemon] = params[:extra][:git_daemon] == 'true' ? true : false
      params[:extra][:git_notify] = params[:extra][:git_notify] == 'true' ? true : false

      update_default_branch = false

      if params[:extra].has_key?(:default_branch) && repository.extra[:default_branch] != params[:extra][:default_branch]
        update_default_branch = true
      end

      ## Update attributes
      repository.extra.update_attributes(params[:extra])

      ## Update repository
      RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has modified repository '#{repository.gitolite_repository_name}'" }
      RedmineGitolite::GitHosting.resync_gitolite(:update_repository, repository.id)

      ## Update repository default branch
      if update_default_branch
        RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has modified default_branch of '#{repository.gitolite_repository_name}' ('#{repository.extra[:default_branch]}')" }
        RedmineGitolite::GitHosting.resync_gitolite(:update_repository_default_branch, repository.id)
      end
    end

end
