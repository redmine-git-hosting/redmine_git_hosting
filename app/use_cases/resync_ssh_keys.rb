class ResyncSshKeys
  unloadable

  include UseCaseBase


  def call
    resync_ssh_key
    super
  end


  private


    def resync_ssh_key
      RedmineGitolite::GitHosting.logger.info { "Forced resync of all ssh keys..." }
      RedmineGitolite::GitHosting.resync_gitolite(:resync_all_ssh_keys, 'all')
    end

end
