class GithostingShellWorker
  include Sidekiq::Worker
  include Githosting::ShellAdapter

  sidekiq_options :queue => :git_hosting, :retry => false

  def perform(data)
    logger.info { "#{data['command']} | #{data['object']}" }
    if data.has_key?('option')
      if data['option'].to_sym == :flush_cache
        logger.info { "Flush Settings Cache !" }
        Setting.check_cache
      end
    end
    githosting_shell.handle_command(data['command'], data['object'])
  end
end
