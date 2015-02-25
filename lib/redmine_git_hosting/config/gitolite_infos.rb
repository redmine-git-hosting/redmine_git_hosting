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
        begin
          RedmineGitHosting::Commands.gitolite_infos
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error('Error while getting Gitolite infos, check your SSH keys path or your Git user.')
          nil
        end
      end


      def gitolite_version
        logger.debug('Getting Gitolite version...')
        @gitolite_version ||= find_version(gitolite_infos)
      end


      def gitolite_banner
        logger.debug('Getting Gitolite banner...')
        gitolite_infos
      end


      def find_version(output)
        return nil if output.blank?
        line = output.split("\n")[0]
        if line =~ /gitolite[ -]v?2./
          2
        elsif line.include?('running gitolite3')
          3
        else
          nil
        end
      end


      def gitolite_command
        if gitolite_version == 2
          ['gl-setup']
        elsif gitolite_version == 3
          ['gitolite', 'setup']
        else
          nil
        end
      end


      def gitolite_repository_count
        return 'This is Gitolite v2, not implemented...' if gitolite_version != 3
        logger.debug('Getting Gitolite physical repositories list...')
        begin
          RedmineGitHosting::Commands.gitolite_repository_count
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error('Error while getting Gitolite physical repositories list')
          0
        end
      end

    end

  end
end
