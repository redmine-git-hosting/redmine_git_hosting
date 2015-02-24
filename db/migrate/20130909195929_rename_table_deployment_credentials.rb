class RenameTableDeploymentCredentials < ActiveRecord::Migration

  def self.up
    remove_index :deployment_credentials, :gitolite_public_key_id
    rename_table :deployment_credentials, :repository_deployment_credentials
  end

  def self.down
    rename_table :repository_deployment_credentials, :deployment_credentials
    add_index :deployment_credentials, :gitolite_public_key_id
  end

end
