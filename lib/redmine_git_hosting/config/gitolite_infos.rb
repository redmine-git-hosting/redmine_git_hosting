module RedmineGitHosting::Config

  module GitoliteInfos

    ##########################
    #                        #
    #     GITOLITE INFOS     #
    #                        #
    ##########################

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def gitolite_infos
        @gitolite_infos ||=
          begin
            RedmineGitHosting::Commands.gitolite_infos
          rescue RedmineGitHosting::Error::GitoliteCommandException => e
            logger.error("Error while getting Gitolite infos")
            nil
          end
      end


      def gitolite_version
        logger.debug("Getting Gitolite version...")
        find_version(gitolite_infos)
      end


      def gitolite_banner
        logger.debug("Getting Gitolite banner...")
        gitolite_infos
      end


      def find_version(output)
        return 0 if output.blank?
        version = nil
        line = output.split("\n")[0]
        if line =~ /gitolite[ -]v?2./
          version = 2
        elsif line.include?('running gitolite3')
          version = 3
        else
          version = 0
        end
        version
      end


      def gitolite_command
        if gitolite_version == 2
          gitolite_command = ['gl-setup']
        elsif gitolite_version == 3
          gitolite_command = ['gitolite', 'setup']
        else
          gitolite_command = nil
        end
        gitolite_command
      end


      def gitolite_repository_count
        return 'This is Gitolite v2, not implemented...' if gitolite_version != 3
        logger.debug("Getting Gitolite physical repositories list...")
        begin
          count = RedmineGitHosting::Commands.gitolite_repository_count
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Error while getting Gitolite physical repositories list")
          count = 0
        end
        count
      end

    end

  end
end
