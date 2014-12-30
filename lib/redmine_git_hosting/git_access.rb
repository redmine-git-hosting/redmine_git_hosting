module RedmineGitHosting
  class GitAccess

    DOWNLOAD_COMMANDS = %w{ git-upload-pack git-upload-archive }
    PUSH_COMMANDS = %w{ git-receive-pack }

    attr_reader :user
    attr_reader :repository


    def download_access_check(actor, repository)
      if actor.is_a?(User)
        user_download_access_check(actor, repository)
      else
        raise 'Wrong actor'
      end
    end


    def upload_access_check(actor, repository)
      if actor.is_a?(User)
        user_upload_access_check(actor, repository)
      else
        raise 'Wrong actor'
      end
    end


    def user_download_access_check(user, repository)
      if user && user.allowed_to?(:view_changesets, repository.project)
        build_status_object(true)
      else
        build_status_object(false, "You don't have access")
      end
    end


    def user_upload_access_check(actor, repository)
      if user && user.allowed_to?(:commit_access, repository.project)
        build_status_object(true)
      else
        build_status_object(false, "You don't have access")
      end
    end


    protected


      def build_status_object(status, message = '')
        GitAccessStatus.new(status, message)
      end

  end
end
