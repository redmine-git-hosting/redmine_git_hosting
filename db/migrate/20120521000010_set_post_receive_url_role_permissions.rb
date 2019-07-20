class SetPostReceiveUrlRolePermissions < ActiveRecord::Migration[4.2]
  def up
    manager_role_name = I18n.t(:default_role_manager, locale: Setting.default_language)
    say "Updating role : '#{manager_role_name}'..."
    manager_role = Role.find_by(name: manager_role_name)
    if !manager_role.nil?
      manager_role.add_permission! :view_repository_post_receive_urls
      manager_role.add_permission! :create_repository_post_receive_urls
      manager_role.add_permission! :edit_repository_post_receive_urls
      manager_role.save
      say 'Done !'
    else
      say "Role '#{manager_role_name}' not found, exit !"
    end

    developer_role_name = I18n.t(:default_role_developer, locale: Setting.default_language)
    say "Updating role : '#{developer_role_name}'..."
    developer_role = Role.find_by(name: developer_role_name)
    if !developer_role.nil?
      developer_role.add_permission! :view_repository_post_receive_urls
      developer_role.save
      say 'Done !'
    else
      say "Role '#{developer_role_name}' not found, exit !"
    end
  end

  def down
    manager_role_name = I18n.t(:default_role_manager, locale: Setting.default_language)
    say "Updating role : '#{manager_role_name}'..."
    manager_role = Role.find_by(name: manager_role_name)
    if !manager_role.nil?
      manager_role.remove_permission! :view_repository_post_receive_urls
      manager_role.remove_permission! :create_repository_post_receive_urls
      manager_role.remove_permission! :edit_repository_post_receive_urls
      manager_role.save
      say 'Done !'
    else
      say "Role '#{manager_role_name}' not found, exit !"
    end

    developer_role_name = I18n.t(:default_role_developer, locale: Setting.default_language)
    say "Updating role : '#{developer_role_name}'..."
    developer_role = Role.find_by(name: developer_role_name)
    if !developer_role.nil?
      developer_role.remove_permission! :view_repository_post_receive_urls
      developer_role.save
      say 'Done !'
    else
      say "Role '#{developer_role_name}' not found, exit !"
    end
  end
end
