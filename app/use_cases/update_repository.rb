class UpdateRepository
  unloadable

  include UseCaseBase

  attr_reader :repository
  attr_reader :message
  attr_reader :update_default_branch
  attr_reader :options


  def initialize(repository, opts = {})
    @repository            = repository
    @message               = opts.delete(:message){ "User '#{User.current.login}' has modified repository '#{repository.gitolite_repository_name}'" }
    @update_default_branch = opts.delete(:update_default_branch){ false }
    @options               = opts
    super
  end


  def call
    update_repository
    super
  end


  private


    def update_repository
      logger.info(message)
      resync_gitolite(:update_repository, repository.id, options)

      ## Update repository default branch if asked
      if update_default_branch
        message = "User '#{User.current.login}' has modified default_branch of '#{repository.gitolite_repository_name}' ('#{repository.extra[:default_branch]}')"
        logger.info(message)
        resync_gitolite(:update_repository_default_branch, repository.id)
      end
    end

end
