# frozen_string_literal: true

module Projects
  class Base
    include RedmineGitHosting::GitoliteAccessor::Methods

    attr_reader :project, :options

    def initialize(project, opts = nil)
      @project = project
      @options = opts
    end

    class << self
      def call(project, opts = nil)
        new(project, opts).call
      end
    end

    def call
      raise NotImplementedError
    end
  end
end
