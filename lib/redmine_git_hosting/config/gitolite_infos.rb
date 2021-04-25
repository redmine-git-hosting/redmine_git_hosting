# frozen_string_literal: true

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
        %i[threads ssh]
      end

      def libgit2_version
        Rugged.libgit2_version.join '.'
      end

      def gitolite_infos
        RedmineGitHosting::Commands.gitolite_infos
      rescue RedmineGitHosting::Error::GitoliteCommandException
        file_logger.error 'Error while getting Gitolite infos, check your SSH keys (path, permissions) or your Git user.'
        nil
      end

      def gitolite_version
        file_logger.debug 'Getting Gitolite version...'
        @gitolite_version ||= find_version gitolite_infos
      end

      def gitolite_banner
        file_logger.debug 'Getting Gitolite banner...'
        gitolite_infos
      end

      def find_version(output)
        return if output.blank?

        line = output.split("\n")[0]
        if /gitolite[ -]v?2./.match?(line)
          2
        elsif line.include? 'running gitolite3'
          3
        end
      end

      def gitolite_command
        case gitolite_version
        when 2
          %w[gl-setup]
        when 3
          %w[gitolite setup]
        end
      end

      def gitolite_repository_count
        return 'This is Gitolite v2, not implemented...' if gitolite_version != 3

        file_logger.debug 'Getting Gitolite physical repositories list...'
        begin
          RedmineGitHosting::Commands.gitolite_repository_count
        rescue RedmineGitHosting::Error::GitoliteCommandException
          file_logger.error 'Error while getting Gitolite physical repositories list'
          0
        end
      end
    end
  end
end
