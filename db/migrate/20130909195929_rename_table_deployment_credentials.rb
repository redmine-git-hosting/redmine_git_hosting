class RenameTableDeploymentCredentials < ActiveRecord::Migration

  def self.up
    rename_table :deployment_credentials, :repository_deployment_credentials
  end

  def self.down
    rename_table :repository_deployment_credentials, :deployment_credentials
  end

end
