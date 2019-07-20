class RenameTableDeploymentCredentials < ActiveRecord::Migration[4.2]
  def up
    remove_index :deployment_credentials, :gitolite_public_key_id
    rename_table :deployment_credentials, :repository_deployment_credentials
  end

  def down
    rename_table :repository_deployment_credentials, :deployment_credentials
    add_index :deployment_credentials, :gitolite_public_key_id
  end
end
