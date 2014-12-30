module RedmineGitHosting::Plugins
  class GitolitePlugin

    class << self

      def plugins
        @plugins ||= []
      end


      def all_plugins
        sweepers + extenders
      end


      def sweepers
        plugins.select { |p| p.name.demodulize == 'BaseSweeper' }.first.subclasses
      end


      def extenders
        plugins.select { |p| p.name.demodulize == 'BaseExtender' }.first.subclasses
      end


      def inherited(klass)
        @plugins ||= []
        @plugins << klass
      end

    end


    private


      def logger
        RedmineGitHosting.logger
      end


      def repository_empty?
        RedmineGitHosting::Commands.sudo_repository_empty?(gitolite_repo_path)
      end


      def directory_exists?(dir)
        RedmineGitHosting::Commands.sudo_dir_exists?(dir)
      end

  end
end
