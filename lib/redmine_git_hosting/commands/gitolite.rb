module RedmineGitHosting::Commands

  module Gitolite

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    #################################
    #                               #
    #  Sudo+Gitolite Shell Wrapper  #
    #                               #
    #################################

    module ClassMethods

      def gitolite_infos
        ssh_capture('info')
      end


      def sudo_update_gitolite!
        if gitolite_command.nil?
          logger.error("gitolite_command is nil, can't update Gitolite !")
          return
        end
        logger.info("Running '#{gitolite_command.join(' ')}' on the Gitolite install ...")
        begin
          sudo_shell(*gitolite_command)
          return true
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error(e.output)
          return false
        end
      end


      def gitolite_repository_count
        sudo_capture('gitolite', 'list-phy-repos').split("\n").length
      end


      # Test if repository is empty on Gitolite side
      #
      def sudo_repository_empty?(repo_path)
        repo_path = File.join(gitolite_home_dir, repo_path, 'objects')
        count = sudo_git_objects_count(repo_path)
        if count.to_i == 0
          true
        else
          false
        end
      end


      def sudo_git_objects_count(repo_path)
        begin
          sudo_capture('eval', 'find', repo_path, '-type', 'f', '|', 'wc', '-l')
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Can't retrieve Git objects count : #{e.output}")
          0
        end
      end

    end

  end

end
