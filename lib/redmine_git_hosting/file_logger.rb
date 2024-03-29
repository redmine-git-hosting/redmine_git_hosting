# frozen_string_literal: true

require 'logger'

module RedmineGitHosting
  class FileLogger < ::Logger
    LOG_LEVELS = %w[debug info warn error].freeze

    def self.init_logs!(appname, logfile, loglevel)
      logger           = new logfile
      logger.progname  = appname
      logger.level     = loglevel
      logger.formatter = proc do |severity, time, _progname, msg|
        "#{time} [#{severity}] #{msg}\n"
      end
      logger
    end
  end
end
