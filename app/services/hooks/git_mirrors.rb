module Hooks
  class GitMirrors
    unloadable


    def initialize(repository, payload)
      @repository = repository
      @project    = repository.project
      @payload    = payload
    end


    def execute
      call_mirrors
    end


    private


    def logger
      RedmineGitolite::Log.get_logger(:git_hooks)
    end


    def call_mirrors
      ## Push to each mirror
      if @repository.repository_mirrors.active.any?
        y = ""

        logger.info { "Notifying mirrors about changes to this repository :" }
        y << "\nNotifying mirrors about changes to this repository :\n"

        @repository.repository_mirrors.active.each do |mirror|
          if mirror.needs_push(@payload)
            logger.info { "Pushing changes to #{mirror.url} ... " }
            y << "  - Pushing changes to #{mirror.url} ... "

            push_failed, push_message = mirror.push

            if push_failed
              logger.error { "Failed!" }
              logger.error { "#{push_message}" }
              y << " [failure]\n"
            else
              logger.info { "Succeeded!" }
              y << " [success]\n"
            end
          end
        end

        return y
      end
    end

  end
end
