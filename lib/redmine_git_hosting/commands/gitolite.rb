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


      def gitolite_repository_count
        sudo_capture('gitolite', 'list-phy-repos').split("\n").length
      end

    end

  end

end
