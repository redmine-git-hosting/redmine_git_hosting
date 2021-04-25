# frozen_string_literal: true

module GitHosting
  class HookLogger
    attr_reader :loglevel

    def initialize(loglevel: 'info')
      @loglevel = loglevel
    end

    def debug(message)
      write message if loglevel == 'debug'
    end

    def info(message)
      write message
    end

    def error(message)
      write message
    end

    private

    def write(message)
      $stdout.sync = true
      $stdout.puts "\e[1G#{message}"
      $stdout.flush
    end
  end
end
