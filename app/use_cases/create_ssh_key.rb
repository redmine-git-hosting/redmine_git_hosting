class CreateSshKey
  unloadable

  include UseCaseBase

  attr_reader :ssh_key
  attr_reader :options


  def initialize(ssh_key, opts = {})
    @ssh_key = ssh_key
    @options = opts
    super
  end


  def call
    create_ssh_key
    super
  end


  private


    def create_ssh_key
      logger.info("User '#{User.current.login}' has added a SSH key")
      resync_gitolite(:add_ssh_key, ssh_key.id, options)
    end

end
