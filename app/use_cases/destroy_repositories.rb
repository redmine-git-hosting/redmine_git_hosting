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
      repositories.each do |repository|
        resync_gitolite(:delete_repository, repository)
      end
    end

end
