module RedmineGitHosting::Plugins::Extenders
  class BaseExtender < RedmineGitHosting::Plugins::GitolitePlugin

    attr_reader :repository
    attr_reader :recovered
    attr_reader :gitolite_repo_name
    attr_reader :gitolite_repo_path
    attr_reader :default_branch
    attr_reader :options


    def initialize(repository, options = {})
      @repository         = repository
      @recovered          = options.delete(:recovered){ false }
      @gitolite_repo_name = repository.gitolite_repository_name
      @gitolite_repo_path = repository.gitolite_repository_path
      @default_branch     = repository.default_branch
      @options            = options
    end


    private


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


      def recovered?
        recovered
      end


      def installable?
        false
      end

  end
end
