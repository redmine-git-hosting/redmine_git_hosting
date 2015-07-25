module RedmineHooks
  class Base
    unloadable

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


    private


      def logger
        RedmineGitHosting.logger
      end

  end
end
