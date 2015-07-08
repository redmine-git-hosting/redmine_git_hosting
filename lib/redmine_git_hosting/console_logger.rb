module RedmineGitHosting
  class ConsoleLogger

    attr_reader :console
    attr_reader :logger

    def initialize(opts = {})
      @console = opts[:console] || false
      @logger ||= RedmineGitHosting.logger
    end

    def info(message)
      puts message if console
      logger.info(message)
    end

    def error(message)
      puts message if console
      logger.error(message)
    end

    # Handle everything else with base object
    def method_missing(m, *args, &block)
      logger.send m, *args, &block
    end

  end
end
