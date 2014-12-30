module RedmineGitHosting
  module GitoliteHandlers
    class RepositoryGitAnnexCreator

      attr_reader :repository
      attr_reader :gitolite_repo_name
      attr_reader :gitolite_repo_path


      def initialize(repository)
        @repository         = repository
        @gitolite_repo_name = repository.gitolite_repository_name
        @gitolite_repo_path = repository.gitolite_repository_path
      end


      def call
        if !git_annex_installed?
          install_git_annex
        else
          logger.warn("GitAnnex already exists in path '#{gitolite_repo_path}'")
        end
      end


      private


        def logger
          RedmineGitHosting.logger
        end


        def install_git_annex
          begin
            RedmineGitHosting::Commands.sudo_capture('git', "--git-dir=#{gitolite_repo_path}", 'annex', 'init')
            logger.info("GitAnnex successfully enabled for repository '#{gitolite_repo_name}'")
          rescue RedmineGitHosting::Error::GitoliteCommandException => e
            logger.error("Error while enabling GitAnnex for repository '#{gitolite_repo_name}'")
          end
        end


        def git_annex_installed?
          directory_exists?(File.join(gitolite_repo_path, 'annex'))
        end


        def directory_exists?(dir)
          RedmineGitHosting::Commands.sudo_dir_exists?(dir)
        end

    end
  end
end
