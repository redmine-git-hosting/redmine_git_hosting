module RedmineHooks
  class GitMirrors < Base
    unloadable

    def call
      call_mirror if needs_push?
    end


    def mirror
      object
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
        y = ''

        logger.info("Pushing changes to #{mirror.url} ... ")
        y << "  - Pushing changes to #{mirror.url} ... "

        push_failed, push_message = RepositoryMirrors::Push.call(mirror)

        if push_failed
          logger.error('Failed!')
          logger.error("#{push_message}")
          y << " [failure]\n"
        else
          logger.info('Succeeded!')
          y << " [success]\n"
        end

        y
      end

  end
end
