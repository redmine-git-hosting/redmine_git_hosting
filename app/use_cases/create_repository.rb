class CreateRepository
  unloadable

  include UseCaseBase

  attr_reader :repository
  attr_reader :options


  def initialize(repository, opts = {})
    @repository = repository
    @options    = opts
    super
  end


  def call
    create_repository
    super
  end


  private


    def create_repository
      RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' created a new repository '#{repository.gitolite_repository_name}'" }
      RedmineGitolite::GitHosting.resync_gitolite(:add_repository, repository.id, options)
    end

end
