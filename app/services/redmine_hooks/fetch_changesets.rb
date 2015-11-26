module RedmineHooks
  class FetchChangesets < Base

    def call
      repository.empty_cache!
      execute_hook do |out|
        out << fetch_changesets
      end
    end


    def repository
      object
    end


    def start_message
      "Fetching changesets for '#{repository.redmine_name}' repository"
    end


    private


      def fetch_changesets
        begin
          repository.fetch_changesets
          log_hook_succeeded
          success_message
        rescue ::Redmine::Scm::Adapters::CommandFailed => e
          log_hook_failed
          logger.error("Error during fetching changesets : #{e.message}")
          failure_message
        end
      end

  end
end
