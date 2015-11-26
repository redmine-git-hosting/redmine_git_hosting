module RedmineHooks
  class Base

    attr_reader :object
    attr_reader :payloads


    def initialize(object, payloads = {})
      @object   = object
      @payloads = payloads
    end


    class << self

      def call(object, payloads = {})
        new(object, payloads).call
      end

    end


    def call
      raise NotImplementedError
    end


    def start_message
      raise NotImplementedError
    end


    private


      def logger
        RedmineGitHosting.logger
      end


      def success_message
        " [success]\n"
      end


      def failure_message
        " [failure]\n"
      end


      def log_hook_succeeded
        logger.info('Succeeded!')
      end


      def log_hook_failed
        logger.error('Failed!')
      end


      def execute_hook(&block)
        y = ''
        logger.info(start_message)
        y << "  - #{start_message} ... "
        yield y
        y
      end

  end
end
