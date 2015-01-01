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

      # Send Git command with Sudo
      #
      def sudo_git_cmd(*params)
        sudo_capture('git', *params)
      end


      def sudo_git_args_for_repo(repo_path)
        [ 'sudo', *sudo_shell_params, 'git' ].concat(git_args_for_repo(repo_path))
      end


      def git_args_for_repo(repo_path)
        [ '--git-dir', repo_path ]
      end


      def sudo_git_mirror_push(repo_path, mirror_url, branch = nil, args = [])
        push_command = [ 'env', 'GIT_SSH=$HOME/.ssh/run_gitolite_admin_ssh', 'git', '--git-dir', repo_path, 'push', *args, mirror_url, branch, '2>&1' ].compact.join(' ')
        sudo_pipe_data(push_command)
      end


      def sudo_git_tag(repo_path)
        sudo_git_cmd(*git_args_for_repo(repo_path), 'tag').split
      rescue RedmineGitHosting::Error::GitoliteCommandException => e
        []
      end


      def sudo_git_rev_list(repo_path, revision, args = [])
        sudo_git_cmd(*git_args_for_repo(repo_path), 'rev-list', *args, revision).split
      rescue RedmineGitHosting::Error::GitoliteCommandException => e
        []
      end


      def sudo_git_rev_parse(repo_path, revision, args = [])
        sudo_git_cmd(*git_args_for_repo(repo_path), 'rev-parse', *args, revision).chomp.strip
      rescue RedmineGitHosting::Error::GitoliteCommandException => e
        ''
      end


      def sudo_git_archive(repo_path, revision, args = [])
        sudo_git_cmd(*git_args_for_repo(repo_path), 'archive', *args, revision)
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


      def git_version
        begin
          sudo_git_cmd('--version', '--no-color')
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Can't retrieve git version: #{e.output}")
          'unknown'
        end
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

    end

  end
end
