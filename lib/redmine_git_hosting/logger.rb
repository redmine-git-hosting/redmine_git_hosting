require 'logger'

module RedmineGitHosting
  class Logger < ::Logger

    LOG_LEVELS = [
      'debug',
      'info',
      'warn',
      'error'
    ]

    def self.init_logs!(appname, logfile, loglevel)
      logger           = new(logfile)
      logger.progname  = appname
      logger.level     = loglevel
      logger.formatter = proc do |severity, time, progname, msg|
        "#{time} [#{severity}] #{msg}\n"
      end
      logger
    end

  end
end
