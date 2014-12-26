module Hooks
  class GitMirrors
    unloadable

    attr_reader :mirror
    attr_reader :payloads
    attr_reader :url


    def initialize(mirror, payloads)
      @mirror   = mirror
      @payloads = payloads
      @url      = mirror.url
    end


    class << self

      def logger
        RedmineGitHosting.logger
      end


      def execute(repository, payloads)
        y = ''

        ## Post to each post-receive URL
        if repository.mirrors.active.any?
          logger.info("Notifying mirrors about changes to this repository :")
          y << "\nNotifying mirrors about changes to this repository :\n"

          repository.mirrors.active.each do |mirror|
            y << self.new(mirror, payloads).execute
          end
        end

        y
      end

    end


    def execute
      call_mirror
    end


    private


      def call_mirror
        if needs_push?
          do_call_mirror
        end
      end


      # If we have an explicit refspec, check it against incoming payloads
      # Special case: if we do not pass in any payloads, return true
      def needs_push?
        return true if payloads.empty?
        return true if mirror.push_mode == RepositoryMirror::PUSHMODE_MIRROR

        refspec_parse = mirror.explicit_refspec.match(/^\+?([^:]*)(:[^:]*)?$/)
        payloads.each do |payload|
          if splitpath = RedmineGitHosting::Utils.refcomp_parse(payload[:ref])
            return true if payload[:ref] == refspec_parse[1]  # Explicit Reference Spec complete path
            return true if splitpath[:name] == refspec_parse[1] # Explicit Reference Spec no type
            return true if mirror.include_all_branches? && splitpath[:type] == "heads"
            return true if mirror.include_all_tags? && splitpath[:type] == "tags"
          end
        end
        false
      end


      def do_call_mirror
        y = ''

        logger.info("Pushing changes to #{url} ... ")
        y << "  - Pushing changes to #{url} ... "

        push_failed, push_message = MirrorPush.new(mirror).call

        if push_failed
          logger.error("Failed!")
          logger.error("#{push_message}")
          y << " [failure]\n"
        else
          logger.info("Succeeded!")
          y << " [success]\n"
        end

        y
      end


      def logger
        RedmineGitHosting.logger
      end

  end
end
