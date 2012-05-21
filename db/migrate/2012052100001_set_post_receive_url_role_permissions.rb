class SetPostReceiveUrlRolePermissions < ActiveRecord::Migration
  def self.up

    begin
      GitHostingObserver.set_update_active(false)

      manager_role   = Role.find_by_name(I18n.t(:default_role_manager))
      manager_role.add_permission! :view_repository_post_receive_urls
      manager_role.add_permission! :edit_repository_post_receive_urls
      manager_role.add_permission! :create_repository_post_receive_urls
      manager_role.save

      developer_role = Role.find_by_name(I18n.t(:default_role_developer))
      developer_role.add_permission! :view_repository_post_receive_urls
      developer_role.save
    rescue
    end

  end

  def self.down

    begin
      GitHostingObserver.set_update_active(false)

      manager_role   = Role.find_by_name(I18n.t(:default_role_manager))
      manager_role.remove_permission! :view_repository_post_receive_urls
      manager_role.remove_permission! :edit_repository_post_receive_urls
      manager_role.remove_permission! :create_repository_post_receive_urls
      manager_role.save

      developer_role = Role.find_by_name(I18n.t(:default_role_developer))
      developer_role.remove_permission! :view_repository_post_receive_urls
      developer_role.save
    rescue
    end
  end
end
