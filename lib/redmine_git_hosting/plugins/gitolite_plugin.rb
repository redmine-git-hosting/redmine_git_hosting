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


      def sudo_git(*params)
        cmd = RedmineGitHosting::Commands.sudo_git_args_for_repo(gitolite_repo_path, git_args).concat(params)
        RedmineGitHosting::Commands.capture(cmd, git_opts)
      end


      # You may override this method to prepend args like environment variables
      # to the git command.
      #
      def git_args
        []
      end


      # You may override this method to pass opts to Open3.capture.
      #
      def git_opts
        {}
      end

  end
end
