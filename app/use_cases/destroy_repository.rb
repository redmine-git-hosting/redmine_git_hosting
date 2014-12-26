class DestroyRepository
  unloadable

  include UseCaseBase

  attr_reader :repositories
  attr_reader :message


  def initialize(repositories, opts = {})
    if repositories.is_a?(Hash)
      @repositories = [repositories]
    elsif repositories.is_a?(Array)
      @repositories = repositories
    end

    @message = opts.delete(:message){ ' ' }
    super
  end


  def call
    destroy_repository
    super
  end


  private


    def destroy_repository
      logger.info(message)
      resync_gitolite(:delete_repositories, repositories)
    end

end
