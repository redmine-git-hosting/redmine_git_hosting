class UpdateRepository
  unloadable

  include UseCaseBase

  attr_reader :repository


  def initialize(repository)
    @repository = repository
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
    end

end
