class DestroyRepository
  unloadable

  include UseCaseBase

  attr_reader :repository


  def initialize(repository)
    @repository = repository
    super
  end


  def call
    destroy_repository
    super
  end


  private


    def destroy_repository
      RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has removed repository '#{repository.gitolite_repository_name}'" }
      repository_data = {}
      repository_data['repo_name'] = repository.gitolite_repository_name
      repository_data['repo_path'] = repository.gitolite_repository_path
      RedmineGitolite::GitHosting.resync_gitolite(:delete_repositories, [repository_data])
    end

end
