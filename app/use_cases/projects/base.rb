module Projects
  class Base
    include RedmineGitHosting::GitoliteAccessor::Methods

    attr_reader :project, :options

    def initialize(project, opts = {})
      @project = project
      @options = opts
    end

    class << self
      def call(project, opts = {})
        new(project, opts).call
      end
    end

    def call
      raise NotImplementedError
    end
  end
end
