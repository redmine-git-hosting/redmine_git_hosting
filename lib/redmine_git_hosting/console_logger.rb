module RedmineGitHosting
  module ConsoleLogger
    extend self

    def title(message, &block)
      info("\n * #{message} :")
      yield if block_given?
      info("   Done !\n\n")
    end

    def debug(message)
      puts message
      logger.debug(message.strip)
    end

    def info(message)
      puts message
      logger.info(message.strip)
    end

    def warn
      puts message
      logger.warn(message.strip)
    end

    def error(message)
      puts message
      logger.error(message.strip)
    end

    private

    def logger
      RedmineGitHosting.logger
    end
  end
end
