module RedmineGitHosting
  module GitoliteWrapper
    class Global < Admin

      def enable_readme_creation
        if all_repository_config.nil?
          admin.transaction do
            gitolite_config.add_repo(create_readme_config)
            gitolite_admin_repo_commit("Enable README file creation for repositories")
          end
        else
          logger.info("'@all' repository already configured, check for RedmineGitHosting key presence")
          admin.transaction do
            add_redmine_key
            gitolite_admin_repo_commit("Enable README file creation for repositories")
          end
        end
      end


      def disable_readme_creation
        if all_repository_config.nil?
          logger.info('README file creation already disabled.')
          return
        else
          admin.transaction do
            remove_redmine_key
            gitolite_admin_repo_commit("Disable README file creation for repositories")
          end
        end
      end


      private


        def redmine_gitolite_key
          'redmine_gitolite_admin_id_rsa'
        end


        def all_repository
          '@all'
        end


        def all_repository_config
          gitolite_config.repos[all_repository]
        end


        def create_readme_config
          repo_conf = ::Gitolite::Config::Repo.new(all_repository)
          repo_conf.permissions = create_readme_perms
          repo_conf
        end


        def create_readme_perms
          permissions = {}
          permissions['RW+'] = {}
          permissions['RW+'][''] = [redmine_gitolite_key]
          [permissions]
        end


        def remove_redmine_key
          repo_conf = all_repository_config

          # RedmineGitHosting key must be in RW+ group
          perms = repo_conf.permissions.select{ |p| p.has_key? 'RW+' }

          # RedmineGitHosting key must be in [RW+][''] group
          # Return if those groups are absent : it means that our key is not here
          return if perms.empty? || !perms[0]['RW+'].include?('')

          # Check for key presence
          users = perms[0]['RW+']['']
          return if !users.include?(redmine_gitolite_key)

          # Delete the key
          repo_conf.permissions[0]['RW+'][''].delete(redmine_gitolite_key)

          # We cannot remove this repository as it may contains other configuration that we didn't check.
          # Instead add a dummy key so the repo_conf is still valid for Gitolite
          # RW+ = <empty string> is not valid
          repo_conf.permissions[0]['RW+'][''].push('DUMMY_REDMINE_KEY') if repo_conf.permissions[0]['RW+'][''].empty?
        end


        def add_redmine_key
          repo_conf = all_repository_config

          # RedmineGitHosting key must be in RW+ group
          perms = repo_conf.permissions.select{ |p| p.has_key? 'RW+' }

          # If not create the RW+ group and add the key
          if perms.empty?
            logger.info("No permissions set for '@all' repository, add RedmineGitHosting key")
            repo_conf.permissions = create_readme_perms
            return
          end

          # RedmineGitHosting key can act on any refspec ('') so it should be it that 'subgroup'
          users = perms[0]['RW+']['']

          # If not create if
          if users.nil?
            logger.info("RedmineGitHosting key is not present, add it !")
            repo_conf.permissions[0]['RW+'][''] = [redmine_gitolite_key]
          # Check that the 'subgroup' contains our key
          elsif !users.include?(redmine_gitolite_key)
            logger.info("RedmineGitHosting key is not present, add it !")
            repo_conf.permissions[0]['RW+'][''].push(redmine_gitolite_key)
          # Our key already here, nothing to do
          else
            logger.info("RedmineGitHosting key is present, nothing to do.")
          end

          # Delete DUMMY_REDMINE_KEY if present
          repo_conf.permissions[0]['RW+'][''].delete('DUMMY_REDMINE_KEY') if repo_conf.permissions[0]['RW+'][''].include?('DUMMY_REDMINE_KEY')
        end

    end
  end
end
