require 'gitolite'

module RedmineGitHosting

  module GitoliteWrapper

    include GitoliteModules::GitoliteConfig
    include GitoliteModules::GitoliteInfos
    include GitoliteModules::Mirroring
    include GitoliteModules::SshWrapper
    include GitoliteModules::SudoWrapper


    ##########################
    #                        #
    #   Gitolite Accessor    #
    #                        #
    ##########################

    class << self

      def gitolite_admin_settings
        {
          git_user: gitolite_user,
          host: "localhost:#{gitolite_server_port}",

          author_name: git_config_username,
          author_email: git_config_email,

          public_key: gitolite_ssh_public_key,
          private_key: gitolite_ssh_private_key,

          key_subdir: gitolite_key_subdir,
          config_file: gitolite_config_file
        }
      end


      def gitolite_admin
        create_temp_dir
        admin_dir = gitolite_admin_dir
        logger.info("Acessing gitolite-admin.git at '#{admin_dir}'")
        ::Gitolite::GitoliteAdmin.new(admin_dir, gitolite_admin_settings)
      end


      def flush_cache(options = {})
        if options.has_key?(:flush_cache) && options[:flush_cache] == true
          logger.info("Flush Settings Cache !")
          Setting.check_cache if Setting.respond_to?(:check_cache)
        end
      end


      WRAPPERS = [
        GitoliteWrapper::Admin, GitoliteWrapper::Repositories,
        GitoliteWrapper::Users, GitoliteWrapper::Projects
      ]

      # Update the Gitolite Repository
      #
      # action: An API action defined in one of the gitolite/* classes.
      def update(action, object, options = {})
        # Symbolize keys before using them
        options = options.symbolize_keys

        # Flush cache if needed
        flush_cache(options)

        # Be sure to have a Gitolite::GitoliteAdmin object.
        # Return nil if issues.
        begin
          admin = gitolite_admin
        rescue Rugged::SshError => e
          logger.error(e.message)
        else
          # Call our wrapper passing the GitoliteAdmin object
          call_gitolite_wrapper(admin, action, object, options)
        end
      end


      def call_gitolite_wrapper(admin, action, object, options = {})
        klass = find_gitolite_wrapper(action)
        unless klass.nil?
          klass.new(admin, action, object, options).send(action)
        else
          raise RedmineGitHosting::Error::GitoliteWrapperException.new(action, "No available Wrapper for action '#{action}' found.")
        end
      end


      def find_gitolite_wrapper(action)
        WRAPPERS.each do |wrappermod|
          return wrappermod if wrappermod.method_defined?(action)
        end
        return nil
      end

    end

  end
end
