module RedmineGitHosting::Plugins::Sweepers
  class BaseSweeper < RedmineGitHosting::Plugins::GitolitePlugin

    attr_reader :repository_data
    attr_reader :gitolite_repo_name
    attr_reader :gitolite_repo_path


    def initialize(repository_data, options = {})
      @repository_data    = repository_data
      @gitolite_repo_name = repository_data['repo_name']
      @gitolite_repo_path = repository_data['repo_path']
    end

  end
end
