module RedmineGitHosting
  module Commands
    module Git
      extend self

      ############################
      #                          #
      #  Sudo+Git Shell Wrapper  #
      #                          #
      ############################


      # Send Git command with Sudo
      #
      def sudo_git(*params)
        if RedmineGitHosting::Config.gitolite_use_sudo?
          cmd = sudo_git_cmd.concat(params)
        else
          cmd = ['git'].concat(params)
        end
        capture(cmd)
      end


      def sudo_git_cmd(args = [])
        sudo.concat(git(args))
      end


      def sudo_git_args_for_repo(repo_path, args = [])
        sudo.concat(git(args)).concat(git_args_for_repo(repo_path))
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
            logger.error("Error while removing Git global parameter : #{key}")
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
          sudo_git('config', '--global', key, value)
          return true
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Error while setting Git global parameter : #{key} (#{value})")
          logger.error(e.output)
          return false
        end
      end


      # Return a hash with global config parameters.
      def sudo_get_git_global_params(namespace)
        begin
          params = sudo_git('config', '--get-regexp', namespace).split("\n")
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Problems to retrieve Gitolite hook parameters in Gitolite config 'namespace : #{namespace}'")
          params = []
        end

        git_config_as_hash(namespace, params)
      end


      def git_version
        begin
          sudo_git('--version')
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Can't retrieve Git version: #{e.output}")
          'unknown'
        end
      end


      private


        # Return the Git command with prepend args (mainly env vars like FOO=BAR git push).
        #
        def git(args = [])
          [*args, Repository::Xitolite.scm_command]
        end


        def git_args_for_repo(repo_path)
          ['--git-dir', repo_path]
        end


        # Returns the global gitconfig prefix for
        # a config with that given key under the
        # hooks namespace.
        #
        def prefix_key(namespace, key)
          [namespace, '.', key].join
        end


        def git_config_as_hash(namespace, params)
          value_hash = {}

          params.each do |value_pair|
            next if value_pair.empty?
            next if !value_pair.start_with?(namespace)
            global_key = value_pair.split(' ')[0]
            value      = value_pair.split(' ')[1]
            key        = global_key.split('.')[1]
            value_hash[key] = value
          end

          value_hash
        end

    end
  end
end
