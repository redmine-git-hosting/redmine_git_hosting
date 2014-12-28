require 'logger'

module RedmineGitHosting
  class Log < Logger

    class << self

      def init_logs!
        logfile = Rails.root.join('log', 'git_hosting.log')
        logger = new(logfile)
        logger.progname = 'RedmineGitHosting'
        logger.level = get_log_level
        logger.formatter = proc do |severity, time, progname, msg|
          "#{time} [#{severity}] #{msg}\n"
        end
        logger
      end


      def get_log_level
        case RedmineGitHosting::Config.get_setting(:gitolite_log_level)
        when 'debug' then
          Logger::DEBUG
        when 'info' then
          Logger::INFO
        when 'warn' then
          Logger::WARN
        when 'error' then
          Logger::ERROR
        end
      end

    end

  end
end
