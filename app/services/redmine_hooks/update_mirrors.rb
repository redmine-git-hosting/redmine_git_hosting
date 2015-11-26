module RedmineHooks
  class UpdateMirrors < Base

    def call
      execute_hook do |out|
        if needs_push?
          out << call_mirror
        else
          out << "#{skip_message}\n"
          logger.info(skip_message)
        end
      end
    end


    def mirror
      object
    end


    # If we have an explicit refspec, check it against incoming payloads
    # Special case: if we do not pass in any payloads, return true
    def needs_push?
      return true if payloads.empty?
      return true if mirror.mirror_mode?
      return check_ref_spec
    end


    def start_message
      "Pushing changes to #{mirror.url}"
    end


    def skip_message
      "This mirror doesn't need to be updated"
    end


    private


      def check_ref_spec
        refspec_parse = RedmineGitHosting::Validators.valid_git_refspec?(mirror.explicit_refspec)
        payloads.each do |payload|
          if splitpath = RedmineGitHosting::Utils::Git.parse_refspec(payload[:ref])
            return true if payload[:ref] == refspec_parse[1]  # Explicit Reference Spec complete path
            return true if splitpath[:name] == refspec_parse[1] # Explicit Reference Spec no type
            return true if mirror.include_all_branches? && splitpath[:type] == 'heads'
            return true if mirror.include_all_tags? && splitpath[:type] == 'tags'
          end
        end
        false
      end


      def call_mirror
        push_failed, push_message = RepositoryMirrors::Push.call(mirror)

        if push_failed
          log_hook_failed
          logger.error(push_message)
          failure_message
        else
          log_hook_succeeded
          success_message
        end
      end

  end
end
