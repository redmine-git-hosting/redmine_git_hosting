module GitoliteAccessor
  unloadable

  class << self

    def create_ssh_key(ssh_key, opts = {})
      logger.info("User '#{User.current.login}' has added a SSH key")
      resync_gitolite(:add_ssh_key, ssh_key.id, opts)
    end


    def destroy_ssh_key(ssh_key, opts = {})
      ssh_key = ssh_key.data_for_destruction if ssh_key.is_a?(GitolitePublicKey)
      logger.info("User '#{User.current.login}' has deleted a SSH key")
      resync_gitolite(:delete_ssh_key, ssh_key, opts)
    end


    def resync_ssh_keys
      logger.info("Forced resync of all ssh keys...")
      resync_gitolite(:resync_all_ssh_keys, 'all')
    end


    def create_repository(repository, opts = {})
      logger.info("User '#{User.current.login}' created a new repository '#{repository.gitolite_repository_name}'")
      resync_gitolite(:add_repository, repository.id, opts)
    end


    def update_repository(repository, opts = {})
      logger.info("User '#{User.current.login}' has modified repository '#{repository.gitolite_repository_name}'")
      resync_gitolite(:update_repository, repository.id, opts)
    end


    def destroy_repository(repository)
      logger.info("User '#{User.current.login}' has removed repository '#{repository.gitolite_repository_name}'")
      resync_gitolite(:delete_repository, repository.data_for_destruction)
    end


    def destroy_repositories(repositories, opts = {})
      message = opts.delete(:message){ ' ' }
      logger.info(message)
      repositories.each do |repository|
        resync_gitolite(:delete_repository, repository)
      end
    end


    def update_projects(projects, opts = {})
      message = opts.delete(:message){ ' ' }
      logger.info(message)
      resync_gitolite(:update_projects, projects, opts)
    end


    def move_project_hierarchy(project)
      logger.info("Move repositories of project : '#{project}'")
      resync_gitolite(:move_repositories, project.id)
    end


    def move_repositories_tree(count)
      logger.info('Gitolite configuration has been modified : repositories hierarchy')
      logger.info("Resync all projects (root projects : '#{count}')...")
      resync_gitolite(:move_repositories_tree, count)
    end


    def purge_trash_bin(repositories)
      resync_gitolite(:purge_recycle_bin, repositories)
    end


    def flush_git_cache
      logger.info('Flush Git Cache !')
      RedmineGitHosting::Cache.flush_cache!
    end


    def flush_settings_cache
      resync_gitolite(:flush_settings_cache, 'flush!', { flush_cache: true })
    end


    def enable_readme_creation
      logger.info('Enable README creation for repositories')
      resync_gitolite(:enable_readme_creation, 'enable_readme_creation')
    end


    def disable_readme_creation
      logger.info('Disable README creation for repositories')
      resync_gitolite(:disable_readme_creation, 'disable_readme_creation')
    end


    private


      def logger
        RedmineGitHosting.logger
      end


      def resync_gitolite(*args)
        RedmineGitHosting.resync_gitolite(*args)
      end

  end

end
