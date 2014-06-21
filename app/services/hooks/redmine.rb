module Hooks
  class Redmine
    unloadable


    def initialize(repository)
      @repository = repository
    end


    def execute
      fetch_changesets
    end


    private


    def logger
      RedmineGitolite::Log.get_logger(:git_hooks)
    end


    def fetch_changesets
      ## Fetch commits from the repository
      y = ""

      logger.info { "Fetching changesets for '#{@repository.redmine_name}' repository ... " }
      y << "  - Fetching changesets for '#{@repository.redmine_name}' repository ... "

      begin
        @repository.fetch_changesets
        logger.info { "Succeeded!" }
        y << " [success]\n"
      rescue Redmine::Scm::Adapters::CommandFailed => e
        logger.error { "Failed!" }
        logger.error { "Error during fetching changesets : #{e.message}" }
        y << " [failure]\n"
      end

      return y
    end

  end
end
