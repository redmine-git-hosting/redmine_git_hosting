module RedmineGitHosting::Plugins::Extenders
  class BaseExtender < RedmineGitHosting::Plugins::GitolitePlugin

    attr_reader :repository
    attr_reader :recovered
    attr_reader :gitolite_repo_name
    attr_reader :gitolite_repo_path
    attr_reader :git_default_branch
    attr_reader :options


    def initialize(repository, options = {})
      @repository         = repository
      @recovered          = options.delete(:recovered) { false }
      @gitolite_repo_name = repository.gitolite_repository_name
      @gitolite_repo_path = repository.gitolite_repository_path
      @git_default_branch = repository.git_default_branch
      @options            = options
    end


    private


      def recovered?
        recovered
      end


      def installable?
        false
      end

  end
end
