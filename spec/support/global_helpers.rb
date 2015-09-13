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

end
