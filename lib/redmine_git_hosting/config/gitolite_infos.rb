module RedmineGitHosting
  module Config
    module GitoliteInfos
      extend self

      ##########################
      #                        #
      #     GITOLITE INFOS     #
      #                        #
      ##########################


      def rugged_features
        Rugged.features
      end


      def rugged_mandatory_features
        [:threads, :ssh]
      end


      def libgit2_version
        Rugged.libgit2_version.join('.')
      end


      def gitolite_infos
        begin
          RedmineGitHosting::Commands.gitolite_infos
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          file_logger.error('Error while getting Gitolite infos, check your SSH keys (path, permissions) or your Git user.')
          nil
        end
      end


      def gitolite_version
        file_logger.debug('Getting Gitolite version...')
        @gitolite_version ||= find_version(gitolite_infos)
      end


      def gitolite_banner
        file_logger.debug('Getting Gitolite banner...')
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
        file_logger.debug('Getting Gitolite physical repositories list...')
        begin
          RedmineGitHosting::Commands.gitolite_repository_count
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          file_logger.error('Error while getting Gitolite physical repositories list')
          0
        end
      end

    end
  end
end
