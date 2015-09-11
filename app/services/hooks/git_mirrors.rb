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
          logger.info('Notifying mirrors about changes to this repository :')
          y << "\nNotifying mirrors about changes to this repository :\n"

          repository.mirrors.active.each do |mirror|
            y << self.new(mirror, payloads).execute
          end
        end

        y
      end

    end


    def execute
      y = ''

      logger.info("Pushing changes to #{url} ... ")
      y << "  - Pushing changes to #{url} ... "

      if needs_push?
        y << call_mirror
      else
        y << "This mirror doesn't need to be updated\n"
      end

      y
    end


    private


      # If we have an explicit refspec, check it against incoming payloads
      # Special case: if we do not pass in any payloads, return true
      def needs_push?
        return true if payloads.empty?
        return true if mirror.mirror_mode?
        return check_ref_spec
      end


      def check_ref_spec
        refspec_parse = mirror.explicit_refspec.match(/^\+?([^:]*)(:[^:]*)?$/)
        payloads.each do |payload|
          if splitpath = RedmineGitHosting::Utils.refcomp_parse(payload[:ref])
            return true if payload[:ref] == refspec_parse[1]  # Explicit Reference Spec complete path
            return true if splitpath[:name] == refspec_parse[1] # Explicit Reference Spec no type
            return true if mirror.include_all_branches? && splitpath[:type] == 'heads'
            return true if mirror.include_all_tags? && splitpath[:type] == 'tags'
          end
        end
        false
      end


      def call_mirror
        push_failed, push_message = MirrorPush.new(mirror).call

        if push_failed
          logger.error('Failed!')
          logger.error("#{push_message}")
          " [failure]\n"
        else
          logger.info('Succeeded!')
          " [success]\n"
        end
      end


      def logger
        RedmineGitHosting.logger
      end

  end
end
