require 'gitolite'

module RedmineGitHosting
  module GitoliteWrapper

    ##########################
    #                        #
    #   Gitolite Accessor    #
    #                        #
    ##########################

    class << self

      def logger
        RedmineGitHosting.logger
      end


      WRAPPERS = [
        GitoliteWrapper::Admin, GitoliteWrapper::Repositories,
        GitoliteWrapper::Users, GitoliteWrapper::Projects,
        GitoliteWrapper::Global
      ]


      # Update the Gitolite Repository
      #
      # action: An API action defined in one of the gitolite/* classes.
      def resync_gitolite(action, object, options = {})
        # Symbolize keys before using them
        options = options.symbolize_keys

        # Flush cache if needed
        flush_cache(options)

        # Be sure to have a Gitolite::GitoliteAdmin object.
        # Return nil if issues.
        begin
          admin = gitolite_admin
        rescue Rugged::SshError => e
          logger.error 'Invalid Gitolite Admin SSH Keys'
          logger.error(e.message)
        rescue Rugged::NetworkError => e
          logger.error 'Access denied for Gitolite Admin SSH Keys'
          logger.error(e.message)
        else
          begin
            # Call our wrapper passing the GitoliteAdmin object
            call_gitolite_wrapper(admin, action, object, options)
          rescue RedmineGitHosting::Error::GitoliteWrapperException => e
            logger.error(e.message)
          end
        end
      end


      private


        def flush_cache(options = {})
          if options.has_key?(:flush_cache) && options[:flush_cache] == true
            logger.info('Flush Settings Cache !')
            Setting.check_cache if Setting.respond_to?(:check_cache)
          end
        end


        def gitolite_admin
          RedmineGitHosting::Config.create_temp_dir
          logger.info("Accessing gitolite-admin.git at '#{gitolite_admin_dir}'")
          ::Gitolite::GitoliteAdmin.new(gitolite_admin_dir, gitolite_admin_settings)
        end


        def gitolite_admin_dir
          RedmineGitHosting::Config.gitolite_admin_dir
        end


        def call_gitolite_wrapper(admin, action, object, options = {})
          klass = find_gitolite_wrapper(action)
          if !klass.nil?
            klass.new(admin, action, object, options).send(action)
          else
            raise RedmineGitHosting::Error::GitoliteWrapperException.new("No available Wrapper for action '#{action}' found.")
          end
        end


        def find_gitolite_wrapper(action)
          WRAPPERS.each do |wrappermod|
            return wrappermod if wrappermod.method_defined?(action)
          end
          return nil
        end


        def gitolite_admin_settings
          {
            git_user:     RedmineGitHosting::Config.gitolite_user,
            host:         "#{RedmineGitHosting::Config.gitolite_server_host}:#{RedmineGitHosting::Config.gitolite_server_port}",
            author_name:  RedmineGitHosting::Config.git_config_username,
            author_email: RedmineGitHosting::Config.git_config_email,
            public_key:   RedmineGitHosting::Config.gitolite_ssh_public_key,
            private_key:  RedmineGitHosting::Config.gitolite_ssh_private_key,
            key_subdir:   RedmineGitHosting::Config.gitolite_key_subdir,
            config_file:  RedmineGitHosting::Config.gitolite_config_file,
            config_dir:   RedmineGitHosting::Config.gitolite_config_dir
          }
        end

    end

  end
end
