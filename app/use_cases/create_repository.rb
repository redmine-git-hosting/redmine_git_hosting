class CreateRepository
  unloadable

  include UseCaseBase

  attr_reader :repository
  attr_reader :params


  def initialize(repository, params)
    @repository = repository
    @params     = params
    super
  end


  def call
    create_repository
    super
  end


  private


    def create_repository
      params[:extra][:git_daemon] = params[:extra][:git_daemon] == 'true' ? true : false
      params[:extra][:git_notify] = params[:extra][:git_notify] == 'true' ? true : false

      repository.extra.update_attributes(params[:extra])

      RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' created a new repository '#{repository.gitolite_repository_name}'" }
      RedmineGitolite::GitHosting.resync_gitolite(:add_repository, repository.id, creation_options)
    end


    def creation_options
      params[:repository][:create_readme] == 'true' ? {:create_readme_file => true} : {:create_readme_file => false}
    end

end
