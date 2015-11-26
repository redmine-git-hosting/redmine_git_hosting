module Projects
  class ExecuteHooks

    attr_reader :project
    attr_reader :hook_type
    attr_reader :params


    def initialize(project, hook_type, params = {})
      @project    = project
      @hook_type  = hook_type
      @params     = params
    end


    class << self

      def call(project, hook_type, params = {})
        new(project, hook_type, params).call
      end

    end


    def call
      self.send("execute_#{hook_type}_hook")
    end


    private


      def execute_github_hook
        RedmineHooks::GithubIssuesSync.call(project, params)
      end

  end
end
