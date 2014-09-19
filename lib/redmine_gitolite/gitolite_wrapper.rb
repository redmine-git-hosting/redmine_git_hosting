require 'gitolite'

module RedmineGitolite

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


      def admin
        create_temp_dir
        admin_dir = gitolite_admin_dir
        logger.info { "Acessing gitolite-admin.git at '#{admin_dir}'" }
        begin
          Gitolite::GitoliteAdmin.new(admin_dir, gitolite_admin_settings)
        rescue => e
          logger.error { e.message }
          return nil
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
        options = options.symbolize_keys

        if options.has_key?(:flush_cache) && options[:flush_cache] == true
          logger.info { "Flush Settings Cache !" }
          Setting.check_cache if Setting.respond_to?(:check_cache)
        end

        WRAPPERS.each do |wrappermod|
          if wrappermod.method_defined?(action)
            return wrappermod.new(action, object, options).send(action)
          end
        end

        raise GitoliteWrapperException.new(action, "No available Wrapper for action '#{action}' found.")
      end

    end

    # Used to register errors when pulling and pushing the conf file
    class GitoliteWrapperException < StandardError
      attr_reader :command
      attr_reader :output

      def initialize(command, output)
        @command = command
        @output  = output
      end
    end

  end
end
