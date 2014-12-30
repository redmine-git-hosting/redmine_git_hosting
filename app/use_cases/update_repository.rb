class UpdateRepository
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
    update_repository
    super
  end


  private


    def update_repository
      logger.info("User '#{User.current.login}' has modified repository '#{repository.gitolite_repository_name}'")
      resync_gitolite(:update_repository, repository.id, options)
    end

end
