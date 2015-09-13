module GlobalHelpers

  def create_user_with_permissions(project, permissions: [], login: nil)
    role = Role.find_by_name('Manager')
    role = FactoryGirl.create(:role, name: 'Manager') if role.nil?
    role.permissions += permissions
    role.save!

    if login.nil?
      user = FactoryGirl.create(:user)
    else
      user = FactoryGirl.create(:user, login: login)
    end


    members = Member.new(role_ids: [role.id], user_id: user.id)
    project.members << members

    return user
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
    user = FactoryGirl.create(:user, login: login, admin: admin) if user.nil?
    user
  end


  def create_ssh_key(opts = {})
    FactoryGirl.create(:gitolite_public_key, opts)
  end


  def build_ssh_key(opts = {})
    FactoryGirl.build(:gitolite_public_key, opts)
  end


  def create_git_repository(project, opts = {})
    repository = create_repository(:repository_gitolite, project, opts)
    build_extra(repository)
    repository
  end


  def create_svn_repository(project, opts = {})
    create_repository(:repository_svn, project, opts)
  end


  def create_repository(type, project, opts = {})
    FactoryGirl.create(type, opts.merge(project_id: project.id))
  end


  def build_extra(repository)
    extra = repository.build_extra(default_branch: 'master', key: RedmineGitHosting::Utils::Crypto.generate_secret(64))
    extra.save!
  end


  def enable_smart_http(repository)
    repository.extra[:git_http] = 2
    repository.extra.save!
  end


  def disable_smart_http(repository)
    repository.extra[:git_http] = 0
    repository.extra.save!
  end


  def enable_public_repo(repository)
    repository.extra[:public_repo] = true
    repository.extra.save!
  end


  def disable_public_repo(repository)
    repository.extra[:public_repo] = false
    repository.extra.save!
  end

end
