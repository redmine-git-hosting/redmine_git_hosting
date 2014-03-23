class GithostingShellWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :git_hosting, :retry => false

  def perform(data)
    logger.info { "#{data['command']} | #{data['object']} | #{data['options']}" }
    githosting_shell = RedmineGitolite::Shell.new(data['command'], data['object'], data['options'])
    githosting_shell.handle_command
  end
end
