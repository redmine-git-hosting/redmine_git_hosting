module RedmineHooks
  class FetchChangesets < Base
    unloadable

    def call
      repository.empty_cache!
      fetch_changesets
    end


    def repository
      object
    end


    def start_message
      "Fetching changesets for '#{repository.redmine_name}' repository"
    end


    private


      def fetch_changesets
        execute_hook do |y|
          begin
            repository.fetch_changesets
            log_hook_succeeded
            y << success_message
          rescue ::Redmine::Scm::Adapters::CommandFailed => e
            log_hook_failed
            logger.error("Error during fetching changesets : #{e.message}")
            y << failure_message
          end
        end
      end

  end
end
