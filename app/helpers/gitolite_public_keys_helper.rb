module GitolitePublicKeysHelper

  def keylabel(key)
    key.user == User.current ? "#{key.title}" : "#{key.user.login}@#{key.title}"
  end


  def can_create_deployment_keys_for_some_project(theuser = User.current)
    return true if theuser.admin?
    theuser.projects_by_role.each_key do |role|
      return true if role.allowed_to?(:create_repository_deployment_credentials)
    end
    return false
  end

end
