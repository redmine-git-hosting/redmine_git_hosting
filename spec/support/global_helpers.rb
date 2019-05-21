module GlobalHelpers
  def create_user_with_permissions(project, permissions: [], login: nil)
    role = Role.find_by_name('Manager')
    role = FactoryBot.create(:role, name: 'Manager') if role.nil?
    role.permissions += permissions
    role.save!

    if login.nil?
      user = FactoryBot.create(:user)
    else
      user = FactoryBot.create(:user, login: login)
    end

    member = Member.new(role_ids: [role.id], user_id: user.id)
    project.members << member

    user
  end


  def create_project(identifier = nil)
    if identifier.nil?
      FactoryBot.create(:project)
    else
      project = Project.find_by_identifier(identifier)
      project = FactoryBot.create(:project, identifier: identifier) if project.nil?
      project
    end
  end


  def set_session_user(user)
    request.session[:user_id] = user.id
  end


  def create_anonymous_user
    create_user('git_anonymous')
  end


  def create_admin_user
    create_user('git_admin', admin: true)
  end


  def create_user(login, admin: false)
    user = User.find_by_login(login)
    user = FactoryBot.create(:user, login: login, admin: admin) if user.nil?
    user
  end


  def create_ssh_key(opts = {})
    FactoryBot.create(:gitolite_public_key, opts)
  end


  def build_ssh_key(opts = {})
    FactoryBot.build(:gitolite_public_key, opts)
  end


  def build_git_repository(opts = {})
    FactoryBot.build(:repository_gitolite, opts)
  end


  def find_or_create_git_repository(opts = {})
    repository = Repository::Xitolite.find_by_identifier(opts[:identifier])
    if repository.nil?
      repository = FactoryBot.create(:repository_gitolite, opts)
      build_extra(repository)
    end
    repository
  end


  def create_git_repository(opts = {})
    repository = FactoryBot.create(:repository_gitolite, opts)
    build_extra(repository)
    repository
  end


  def build_extra(repository)
    extra = repository.build_extra(default_branch: 'master', key: RedmineGitHosting::Utils::Crypto.generate_secret(64))
    extra.save!
  end


  def create_svn_repository(opts = {})
    FactoryBot.create(:repository_svn, opts)
  end


  def load_yaml_fixture(fixture)
    YAML::load(load_fixture(fixture))
  end


  def load_fixture(fixture)
    File.read(RedmineGitHosting.plugin_spec_dir('fixtures', fixture))
  end

end
