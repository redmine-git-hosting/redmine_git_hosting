module RedmineGitHosting::Commands

  module Git

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    ############################
    #                          #
    #  Sudo+Git Shell Wrapper  #
    #                          #
    ############################

    module ClassMethods

      def sudo_update_gitolite!
        logger.info("Running '#{gitolite_command.join(' ')}' on the Gitolite install ...")
        begin
          sudo_shell(*gitolite_command)
          return true
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error(e.output)
          return false
        end
      end


      # Send Git command with Sudo
      #
      def sudo_git_cmd(*params)
        sudo_capture('git', *params)
      end


      def sudo_unset_git_global_param(key)
        logger.info("Unset Git global parameter : #{key}")

        begin
          _, _, code = sudo_shell('git', 'config', '--global', '--unset', key)
          return true
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          if code == 5
            return true
          else
            logger.error("Error while removing Git hooks global parameter : #{key}")
            logger.error(e.output)
            return false
          end
        end
      end


      def sudo_set_git_global_param(namespace, key, value)
        key = prefix_key(namespace, key)

        return sudo_unset_git_global_param(key) if value == ''

        logger.info("Set Git global parameter : #{key} (#{value})")

        begin
          sudo_capture('git', 'config', '--global', key, value)
          return true
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Error while setting Git hooks global parameter : #{key} (#{value})")
          logger.error(e.output)
          return false
        end
      end


      # Return a hash with global config parameters.
      def sudo_get_git_global_params(namespace)
        begin
          params = sudo_capture('git', 'config', '-f', '.gitconfig', '--get-regexp', namespace).split("\n")
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Problems to retrieve Gitolite hook parameters in Gitolite config 'namespace : #{namespace}'")
          params = []
        end

        git_config_as_hash(params)
      end


      private


        # Returns the global gitconfig prefix for
        # a config with that given key under the
        # hooks namespace.
        #
        def prefix_key(namespace, key)
          [namespace, '.', key].join
        end


        def git_config_as_hash(params)
          value_hash = {}

          params.each do |value_pair|
            global_key = value_pair.split(' ')[0]
            value      = value_pair.split(' ')[1]
            key        = global_key.split('.')[1]
            value_hash[key] = value
          end

          value_hash
        end


        def gitolite_command
          RedmineGitHosting::Config.gitolite_command
        end

    end

  end
end
