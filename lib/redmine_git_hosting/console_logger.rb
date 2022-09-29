# frozen_string_literal: true

module RedmineGitHosting
  module ConsoleLogger
    extend self

    def title(message)
      info "\n * #{message}:"
      yield if block_given?
      info " Done!\n\n"
    end

    def debug(message)
      to_console message
      logger.debug message.strip
    end

    def info(message)
      to_console message
      logger.info message.strip
    end

    def warn
      to_console message
      logger.warn message.strip
    end

    def error(message)
      to_console message
      logger.error message.strip
    end

    private

    def to_console(message)
      puts message
    end

    def logger
      RedmineGitHosting.logger
    end
  end
end
