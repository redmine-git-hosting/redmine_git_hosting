module RedmineGitHosting::Plugins::Extenders
  class BaseExtender < RedmineGitHosting::Plugins::GitolitePlugin
    attr_reader :repository, :recovered, :gitolite_repo_name, :gitolite_repo_path, :git_default_branch, :options

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
