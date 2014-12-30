class DestroyRepositories
  unloadable

  include UseCaseBase

  attr_reader :repositories
  attr_reader :message


  def initialize(repositories, opts = {})
    @repositories = repositories
    @message      = opts.delete(:message){ ' ' }
    super
  end


  def call
    destroy_repositories
    super
  end


  private


    def destroy_repositories
      logger.info(message)
      resync_gitolite(:delete_repositories, repositories)
    end

end
