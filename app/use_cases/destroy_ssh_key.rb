class DestroySshKey
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
    destroy_ssh_key
    super
  end


  private


    def destroy_ssh_key
      RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has deleted a SSH key" }
      RedmineGitolite::GitHosting.resync_gitolite(:delete_ssh_key, ssh_key.to_yaml, options)
    end

end
