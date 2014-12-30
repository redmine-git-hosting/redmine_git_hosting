class GithostingShellWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :redmine_git_hosting, :retry => false

  def perform(command, object, options = {})
    logger.info("#{command} | #{object} | #{options}")
    RedmineGitHosting::GitoliteWrapper.resync_gitolite(command, object, options)
  end
end
