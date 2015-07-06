module Hooks
  class Redmine < Base
    unloadable

    def call
      repository.empty_cache!
      fetch_changesets
    end


    def repository
      object
    end


    private


      def fetch_changesets
        y = ''

        logger.info("Fetching changesets for '#{repository.redmine_name}' repository ... ")
        y << "  - Fetching changesets for '#{repository.redmine_name}' repository ... "

        begin
          repository.fetch_changesets
          logger.info('Succeeded!')
          y << " [success]\n"
        rescue ::Redmine::Scm::Adapters::CommandFailed => e
          logger.error('Failed!')
          logger.error("Error during fetching changesets : #{e.message}")
          y << " [failure]\n"
        end

        y
      end

  end
end
