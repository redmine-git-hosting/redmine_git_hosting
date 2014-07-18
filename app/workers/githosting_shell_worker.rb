class GithostingShellWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :redmine_git_hosting, :retry => false

  def perform(command, object, options = {})
    logger.info { "#{command} | #{object} | #{options}" }
    RedmineGitolite::GitoliteWrapper.update(command, object, options)
  end
end
