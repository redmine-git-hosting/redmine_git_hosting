module RedmineGitHosting
  module GitoliteAccessor
    extend self

    module Methods
      private

      def gitolite_accessor
        RedmineGitHosting::GitoliteAccessor
      end
    end

    def create_ssh_key(ssh_key, opts = {})
      logger.info("User '#{User.current.login}' has added a SSH key")
      resync_gitolite(:add_ssh_key, ssh_key.id, opts)
    end

    def destroy_ssh_key(ssh_key, opts = {})
      ssh_key = ssh_key.data_for_destruction if ssh_key.is_a?(GitolitePublicKey)
      logger.info("User '#{User.current.login}' has deleted a SSH key")
      resync_gitolite(:delete_ssh_key, ssh_key, opts)
    end

    def resync_ssh_keys(opts = {})
      logger.info('Forced resync of all ssh keys...')
      resync_gitolite(:resync_ssh_keys, 'all', opts)
    end

    def regenerate_ssh_keys(opts = {})
      logger.info('Forced regenerate of all ssh keys...')
      resync_gitolite(:regenerate_ssh_keys, 'all', opts)
    end

    def create_repository(repository, opts = {})
      logger.info("User '#{User.current.login}' has created a new repository '#{repository.gitolite_repository_name}'")
      resync_gitolite(:add_repository, repository.id, opts)
    end

    def update_repository(repository, opts = {})
      logger.info("User '#{User.current.login}' has modified repository '#{repository.gitolite_repository_name}'")
      resync_gitolite(:update_repository, repository.id, opts)
    end

    def move_repository(repository, opts = {})
      logger.info("User '#{User.current.login}' has moved repository '#{repository.gitolite_repository_name}'")
      resync_gitolite(:move_repository, repository.id, opts)
    end

    def destroy_repository(repository, opts = {})
      logger.info("User '#{User.current.login}' has removed repository '#{repository.gitolite_repository_name}'")
      resync_gitolite(:delete_repository, repository.data_for_destruction, opts)
    end

    def destroy_repositories(repositories, opts = {})
      message = opts.delete(:message) { ' ' }
      logger.info(message)
      repositories.each do |repository|
        resync_gitolite(:delete_repository, repository)
      end
    end

    def update_projects(projects, opts = {})
      message = opts.delete(:message) { ' ' }
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

    def purge_recycle_bin
      resync_gitolite(:purge_recycle_bin, 'all')
    end

    def delete_from_recycle_bin(repositories)
      resync_gitolite(:delete_from_recycle_bin, repositories)
    end

    def flush_git_cache
      logger.info('Flush Git Cache !')
      RedmineGitHosting::Cache.flush_cache!
    end

    def flush_settings_cache
      resync_gitolite(:flush_settings_cache, 'flush!', { flush_cache: true })
    end

    def enable_rw_access
      logger.info('Enable RW access on all Gitolite repositories')
      resync_gitolite(:enable_rw_access, 'enable_rw_access')
    end

    def disable_rw_access
      logger.info('Disable RW access on all Gitolite repositories')
      resync_gitolite(:disable_rw_access, 'disable_rw_access')
    end

    private

    def logger
      RedmineGitHosting.logger
    end

    def resync_gitolite(command, object, options = {})
      if options.has_key?(:bypass_sidekiq) && options[:bypass_sidekiq] == true
        bypass = true
      else
        bypass = false
      end

      if RedmineGitHosting::Config.gitolite_use_sidekiq? &&
         RedmineGitHosting::Config.sidekiq_available? && !bypass
        GithostingShellWorker.maybe_do(command, object, options)
      else
        GitoliteWrapper.resync_gitolite(command, object, options)
      end
    end
  end
end
