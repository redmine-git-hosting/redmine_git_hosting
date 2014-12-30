class CreateRepository
  unloadable

  include UseCaseBase

  attr_reader :repository
  attr_reader :options


  def initialize(repository, opts = {})
    @repository = repository
    @options    = opts
    super
  end


  def call
    set_repository_extras
    create_repository
    super
  end


  private


    def set_repository_extras
      extra = repository.build_git_extra(default_extra_options)
      extra.save!
    end


    def default_extra_options
      enable_git_annex? ? git_annex_repository_options : standard_repository_options
    end


    def enable_git_annex?
      options[:enable_git_annex]
    end


    def standard_repository_options
      {
        git_http:       RedmineGitHosting::Config.gitolite_http_by_default?,
        git_daemon:     RedmineGitHosting::Config.gitolite_daemon_by_default?,
        git_notify:     RedmineGitHosting::Config.gitolite_notify_by_default?,
        git_annex:      false,
        default_branch: 'master',
        key:            RedmineGitHosting::Utils.generate_secret(64)
      }
    end


    def git_annex_repository_options
      {
        git_http:       0,
        git_daemon:     false,
        git_notify:     false,
        git_annex:      true,
        default_branch: 'git-annex',
        key:            RedmineGitHosting::Utils.generate_secret(64)
      }
    end


    def create_repository
      logger.info("User '#{User.current.login}' created a new repository '#{repository.gitolite_repository_name}'")
      resync_gitolite(:add_repository, repository.id, options)
    end

end
