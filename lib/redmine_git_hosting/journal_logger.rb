# frozen_string_literal: true

module RedmineGitHosting
  # @see https://github.com/theforeman/journald-logger
  if defined? ::Journald::Logger
    class JournalLogger < ::Journald::Logger
      def self.init_logs!(progname, loglevel)
        logger = new progname, type: progname
        logger.level = loglevel

        logger
      end

      def debug(msg)
        super msg2str(msg)
      end

      def info(msg)
        super msg2str(msg)
      end

      def warn(msg)
        super msg2str(msg)
      end

      def error(msg)
        super msg2str(msg)
      end

      def msg2str(msg)
        case msg
        when ::String
          msg
        else
          msg.inspect
        end
      end
    end
  else
    module JournalLogger
    end
  end
end
