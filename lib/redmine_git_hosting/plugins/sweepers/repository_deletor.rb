module RedmineGitHosting::Plugins::Sweepers
  class RepositoryDeletor < BaseSweeper

    def post_delete
      # Delete hook param if needed
      move_repository_to_recycle if delete_repository?
    end


    private


      def move_repository_to_recycle
        if repository_data.is_a?(Hash)
          RedmineGitHosting::Recycle.move_repository_to_recycle(repository_data)
        elsif repository_data.is_a?(Array)
          repository_data.each do |repo|
            RedmineGitHosting::Recycle.move_repository_to_recycle(repo)
          end
        end
      end

  end
end
