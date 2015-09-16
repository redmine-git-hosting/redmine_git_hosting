module RedmineGitHosting
  module GitoliteWrappers
    module Global
      class EnableRwAccess < GitoliteWrappers::Base

        include Common

        def call
          if all_repository_config.nil?
            admin.transaction do
              gitolite_config.add_repo(rw_access_config)
              gitolite_admin_repo_commit('Enable RW access on all Gitolite repositories')
            end
          else
            logger.info("#{context} : '@all' repository already configured, check for RedmineGitHosting key presence")
            admin.transaction do
              add_redmine_key
              gitolite_admin_repo_commit('Enable RW access on all Gitolite repositories')
            end
          end
        end


        def add_redmine_key
          # RedmineGitHosting key must be in RW+ group
          # If not create the RW+ group and add the key
          if perms.empty?
            logger.info("#{context} : No permissions set for '@all' repository, add RedmineGitHosting key")
            repo_conf.permissions = rw_access_perms
          elsif users.nil?
            logger.info("#{context} : RedmineGitHosting key is not present, add it !")
            repo_conf.permissions[0]['RW+'][''] = [redmine_gitolite_key]
          elsif !users.include?(redmine_gitolite_key)
            logger.info("#{context} : RedmineGitHosting key is not present, add it !")
            repo_conf.permissions[0]['RW+'][''].push(redmine_gitolite_key)
          else
            logger.info("#{context} : RedmineGitHosting key is present, nothing to do.")
          end

          # Delete DUMMY_REDMINE_KEY if present
          repo_conf.permissions[0]['RW+'][''].delete('DUMMY_REDMINE_KEY') if repo_conf.permissions[0]['RW+'][''].include?('DUMMY_REDMINE_KEY')
        end

      end
    end
  end
end
