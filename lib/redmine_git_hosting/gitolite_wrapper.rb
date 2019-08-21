require 'gitolite'

module RedmineGitHosting
  module GitoliteWrapper
    extend self

    # Update the Gitolite Repository
    #
    # action: An API action defined in one of the gitolite/* classes.
    #
    def resync_gitolite(action, object, options = {})
      # Symbolize keys before using them
      action  = action.to_sym
      options = options.symbolize_keys

      # Flush cache if needed
      flush_cache(options)

      # Return if the action is only to flush cache on Sidekiq side
      if action == :flush_settings_cache
        logger.info('Settings cache flushed!')
        return
      else
        execute_action(action, object, options)
      end
    end


    private


      def flush_cache(options = {})
        if options.has_key?(:flush_cache) && options[:flush_cache] == true
          logger.info('Flush Settings Cache !')
          Setting.check_cache if Setting.respond_to?(:check_cache)
        end
      end


      # Be sure to have a Gitolite::GitoliteAdmin object.
      # Return if issues.
      #
      def execute_action(action, object, options = {})
        begin
          admin = gitolite_admin
        rescue Rugged::SshError => e
          logger.error 'Invalid Gitolite Admin SSH Keys'
          logger.error(e.message)
        rescue Rugged::NetworkError => e
          logger.error 'Access denied for Gitolite Admin SSH Keys'
          logger.error(e.message)
        rescue Rugged::OSError => e
          logger.error 'Invalid connection params'
          logger.error(e.message)
        rescue Rugged::RepositoryError => e
          logger.error "Gitolite couldn't write to its admin repo copy"
          logger.error "Try recreating '#{gitolite_admin_dir}'"
          logger.error(e.message)
        else
          call_gitolite_wrapper(action, admin, object, options)
        end
      end


      def gitolite_admin
        RedmineGitHosting::Config.create_temp_dir
        logger.debug("Accessing gitolite-admin.git at '#{gitolite_admin_dir}'")
        ::Gitolite::GitoliteAdmin.new(gitolite_admin_dir, gitolite_admin_settings)
      end


      def gitolite_admin_dir
        RedmineGitHosting::Config.gitolite_admin_dir
      end


      def call_gitolite_wrapper(action, admin, object, options = {})
        begin
          klass = GitoliteWrappers::Base.find_by_action_name(action)
        rescue RedmineGitHosting::Error::GitoliteWrapperException => e
          logger.error(e.message)
        else
          klass.call(admin, object, options)
        end
      end


      def gitolite_admin_settings
        {
          git_user:     RedmineGitHosting::Config.gitolite_user,
          hostname:     "#{RedmineGitHosting::Config.gitolite_server_host}:#{RedmineGitHosting::Config.gitolite_server_port}",
          host:     "#{RedmineGitHosting::Config.gitolite_server_host}:#{RedmineGitHosting::Config.gitolite_server_port}",
          author_name:  RedmineGitHosting::Config.git_config_username,
          author_email: RedmineGitHosting::Config.git_config_email,
          public_key:   RedmineGitHosting::Config.gitolite_ssh_public_key,
          private_key:  RedmineGitHosting::Config.gitolite_ssh_private_key,
          key_subdir:   RedmineGitHosting::Config.gitolite_key_subdir,
          config_file:  RedmineGitHosting::Config.gitolite_config_file,
          config_dir:   RedmineGitHosting::Config.gitolite_config_dir
        }
      end


      def logger
        RedmineGitHosting.logger
      end

  end
end
