class UpdateRepository
  unloadable

  include UseCaseBase

  attr_reader :repository
  attr_reader :update_default_branch


  def initialize(repository, opts = {})
    @repository            = repository
    @update_default_branch = opts.delete(:update_default_branch){ false }
    super
  end


  def call
    update_repository
    super
  end


  private


    def update_repository
      RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has modified repository '#{repository.gitolite_repository_name}'" }
      RedmineGitolite::GitHosting.resync_gitolite(:update_repository, repository.id)

      ## Update repository default branch if asked
      if update_default_branch
        RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has modified default_branch of '#{repository.gitolite_repository_name}' ('#{repository.extra[:default_branch]}')" }
        RedmineGitolite::GitHosting.resync_gitolite(:update_repository_default_branch, repository.id)
      end
    end

end
