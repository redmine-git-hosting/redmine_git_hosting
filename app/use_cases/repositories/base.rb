module Repositories
  class Base

    include RedmineGitHosting::GitoliteAccessor::Methods

    attr_reader :repository
    attr_reader :options
    attr_reader :project


    def initialize(repository, opts = {})
      @repository = repository
      @options    = opts
      @project    = repository.project
    end


    class << self

      def call(repository, opts = {})
        new(repository, opts).call
      end

    end


    def call
      raise NotImplementedError
    end


    private


      def logger
        RedmineGitHosting.logger
      end

  end
end
