module RedmineGitHosting::Plugins::Sweepers
  class RepositoryDeletor < BaseSweeper

    def post_delete
      # Delete hook param if needed
      move_repository_to_recycle if RedmineGitHosting::Config.delete_git_repositories?
    end


    private


      def move_repository_to_recycle
        recycle = RedmineGitHosting::Recycle.new
        if repository_data.is_a?(Hash)
          recycle.move_repository_to_recycle(repository_data)
        elsif repository_data.is_a?(Array)
          repository_data.each do |repo|
            recycle.move_repository_to_recycle(repo)
          end
        end
      end

  end
end
