class DestroyRepository
  unloadable

  include UseCaseBase

  attr_reader :repository


  def initialize(repository, opts = {})
    @repository = repository
    super
  end


  def call
    destroy_repository
    super
  end


  private


    def destroy_repository
      logger.info("User '#{User.current.login}' has removed repository '#{repository.gitolite_repository_name}'")
      resync_gitolite(:delete_repository, repository.data_for_destruction)
    end

end
