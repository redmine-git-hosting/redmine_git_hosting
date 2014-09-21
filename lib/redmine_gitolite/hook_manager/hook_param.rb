module RedmineGitolite::HookManager

  class HookParam


    private


      def logger
        RedmineGitolite::Log.get_logger(:global)
      end


      # Return a hash with global config parameters.
      def get_git_config_params(namespace)
        begin
          params = RedmineGitolite::GitoliteWrapper.sudo_capture('git', 'config', '-f', '.gitconfig', '--get-regexp', namespace).split("\n")
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Problems to retrieve Gitolite hook parameters in Gitolite config 'namespace : #{namespace}'" }
          params = []
        end

        value_hash = {}

        params.each do |value_pair|
          global_key = value_pair.split(' ')[0]
          value      = value_pair.split(' ')[1]
          key        = global_key.split('.')[1]
          value_hash[key] = value
        end

        return value_hash
      end


      def set_git_config_param(namespace, key, value)
        key = prefix_key(namespace, key)

        return unset_git_config_param(key) if value == ''

        logger.info { "Set Git hooks global parameter : #{key} (#{value})" }

        begin
          RedmineGitolite::GitoliteWrapper.sudo_capture('git', 'config', '--global', key, value)
          return true
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Error while setting Git hooks global parameter : #{key} (#{value})" }
          logger.error { e.output }
          return false
        end
      end


      def unset_git_config_param(key)
        logger.info { "Unset Git hooks global parameter : #{key}" }

        begin
          _, _, code = RedmineGitolite::GitoliteWrapper.sudo_shell('git', 'config', '--global', '--unset', key)
          return true
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          if code == 5
            return true
          else
            logger.error { "Error while removing Git hooks global parameter : #{key}" }
            logger.error { e.output }
            return false
          end
        end
      end


      # Returns the global gitconfig prefix for
      # a config with that given key under the
      # hooks namespace.
      #
      def prefix_key(namespace, key)
        [namespace, '.', key].join
      end

  end
end
