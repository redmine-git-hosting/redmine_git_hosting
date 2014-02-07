class CreateDeploymentCredentials < ActiveRecord::Migration

  def self.up
    create_table :deployment_credentials do |t|
      t.references :repository
      t.references :gitolite_public_key
      t.references :user
      t.column :active, :integer, :default => 1
      t.column :perm, :string, :null => false
    end

    add_index :deployment_credentials, :repository_id
    add_index :deployment_credentials, :gitolite_public_key_id

    add_column :gitolite_public_keys, :key_type, :integer, :default => GitolitePublicKey::KEY_TYPE_USER
    add_column :gitolite_public_keys, :delete_when_unused, :boolean, :default => true

    GitHostingObserver.set_update_active(false)

    manager_role_name = I18n.t(:default_role_manager, {:locale => Setting.default_language})
    puts "Updating role : '#{manager_role_name}'..."
    manager_role = Role.find_by_name(manager_role_name)
    if !manager_role.nil?
      manager_role.add_permission! :view_deployment_keys
      manager_role.add_permission! :create_deployment_keys
      manager_role.add_permission! :edit_deployment_keys
      manager_role.save
      puts "done !"
    else
      puts "Role '#{manager_role_name}' not found, exit !"
    end

    developer_role_name = I18n.t(:default_role_developer, {:locale => Setting.default_language})
    puts "Updating role : '#{developer_role_name}'..."
    developer_role = Role.find_by_name(developer_role_name)
    if !developer_role.nil?
      developer_role.add_permission! :view_deployment_keys
      developer_role.save
      puts "done !"
    else
      puts "Role '#{developer_role_name}' not found, exit !"
    end
  end

  def self.down
    drop_table :deployment_credentials
    remove_column :gitolite_public_keys, :key_type
    remove_column :gitolite_public_keys, :delete_when_unused

    GitHostingObserver.set_update_active(false)

    manager_role_name = I18n.t(:default_role_manager, {:locale => Setting.default_language})
    puts "Updating role : '#{manager_role_name}'..."
    manager_role = Role.find_by_name(manager_role_name)
    if !manager_role.nil?
      manager_role.remove_permission! :view_deployment_keys
      manager_role.remove_permission! :create_deployment_keys
      manager_role.remove_permission! :edit_deployment_keys
      manager_role.save
      puts "done !"
    else
      puts "Role '#{manager_role_name}' not found, exit !"
    end

    developer_role_name = I18n.t(:default_role_developer, {:locale => Setting.default_language})
    puts "Updating role : '#{developer_role_name}'..."
    developer_role = Role.find_by_name(developer_role_name)
    if !developer_role.nil?
      developer_role.remove_permission! :view_deployment_keys
      developer_role.save
      puts "done !"
    else
      puts "Role '#{developer_role_name}' not found, exit !"
    end
  end

end
