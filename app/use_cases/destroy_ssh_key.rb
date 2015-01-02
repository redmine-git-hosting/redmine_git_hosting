class DestroySshKey
  unloadable

  include UseCaseBase

  attr_reader :ssh_key


  def initialize(ssh_key)
    @ssh_key = ssh_key
    super
  end


  def call
    destroy_ssh_key
    super
  end


  private


    def destroy_ssh_key
      logger.info("User '#{User.current.login}' has deleted a SSH key")
      resync_gitolite(:delete_ssh_key, ssh_key)
    end

end
