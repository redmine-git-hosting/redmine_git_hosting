module Hooks
  class Redmine
    unloadable

    attr_reader :repository


    def initialize(repository)
      @repository = repository
    end


    def execute
      fetch_changesets
    end


    private


      def logger
        RedmineGitHosting.logger
      end


      def fetch_changesets
        ## Fetch commits from the repository
        y = ""

        logger.info("Fetching changesets for '#{repository.redmine_name}' repository ... ")
        y << "  - Fetching changesets for '#{repository.redmine_name}' repository ... "

        begin
          repository.fetch_changesets
          logger.info("Succeeded!")
          y << " [success]\n"
        rescue ::Redmine::Scm::Adapters::CommandFailed => e
          logger.error("Failed!")
          logger.error("Error during fetching changesets : #{e.message}")
          y << " [failure]\n"
        rescue => e
          logger.error("Failed!")
          logger.error("Error after fetching changesets : #{e.message}")
          y << " [failure]\n"
        end

        return y
      end

  end
end
