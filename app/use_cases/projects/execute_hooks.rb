# frozen_string_literal: true

module Projects
  class ExecuteHooks
    attr_reader :project, :hook_type, :payloads

    def initialize(project, hook_type, payloads = nil)
      @project = project
      @hook_type = hook_type
      @payloads = payloads
    end

    class << self
      def call(project, hook_type, payloads = nil)
        new(project, hook_type, payloads).call
      end
    end

    def call
      send "execute_#{hook_type}_hook"
    end

    private

    def execute_github_hook
      RedmineHooks::GithubIssuesSync.call project, payloads
    end
  end
end
