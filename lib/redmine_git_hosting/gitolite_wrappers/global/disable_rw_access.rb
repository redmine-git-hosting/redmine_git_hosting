module RedmineGitHosting
  module GitoliteWrappers
    module Global
      class DisableRwAccess < GitoliteWrappers::Base

        include Common

        def call
          if all_repository_config.nil?
            logger.info("#{context} : RW access on all Gitolite repositories already disabled.")
            return
          else
            admin.transaction do
              remove_redmine_key
              gitolite_admin_repo_commit('Disable RW access on all Gitolite repositories')
            end
          end
        end


        def remove_redmine_key
          # RedmineGitHosting key must be in [RW+][''] group
          # Return if those groups are absent : it means that our key is not here
          return if perms.empty? || !perms[0]['RW+'].include?('')

          # Check for key presence
          return if !users.include?(redmine_gitolite_key)

          # Delete the key
          repo_conf.permissions[0]['RW+'][''].delete(redmine_gitolite_key)

          # We cannot remove this repository as it may contains other configuration that we didn't check.
          # Instead add a dummy key so the repo_conf is still valid for Gitolite
          # RW+ = <empty string> is not valid
          repo_conf.permissions[0]['RW+'][''].push('DUMMY_REDMINE_KEY') if repo_conf.permissions[0]['RW+'][''].empty?
        end

      end
    end
  end
end
