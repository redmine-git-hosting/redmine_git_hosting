module Projects
  class Update < Base

    def call
      # Adjust daemon status
      disable_git_daemon_if_not_public
      resync
    end


    private


      def disable_git_daemon_if_not_public
        # Go through all gitolite repos and disable Git daemon if necessary
        project.gitolite_repos.each do |repository|
          repository.extra[:git_daemon] = false if repository.git_daemon_enabled? && !project.is_public
          # Save GitExtra in all cases to trigger urls order consistency checks
          repository.extra.save
        end
      end


      def resync
        gitolite_accessor.update_projects([project.id], options)
      end

  end
end
