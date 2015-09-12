module GlobalHelpers

  def create_user_with_permissions(project, permissions = [])
    role = FactoryGirl.create(:role, :name => 'Manager2')
    role.permissions += permissions
    role.save!

    user = FactoryGirl.create(:user)

    members = Member.new(:role_ids => [role.id], :user_id => user.id)
    project.members << members

    return user
  end

end
