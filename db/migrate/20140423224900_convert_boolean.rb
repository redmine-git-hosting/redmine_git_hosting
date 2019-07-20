class ConvertBoolean < ActiveRecord::Migration[4.2]
  def up
    ## GitolitePublicKey
    add_column :gitolite_public_keys, :active_temp, :boolean, default: true, after: :key
    GitolitePublicKey.reset_column_information
    GitolitePublicKey.all.each do |p|
      active_temp = p.active == 1
      say 'Update!'
      p.update_column(:active_temp, active_temp)
    end
    remove_column :gitolite_public_keys, :active
    rename_column :gitolite_public_keys, :active_temp, :active

    add_column :gitolite_public_keys, :delete_when_unused_temp, :boolean, default: true, after: :active
    GitolitePublicKey.reset_column_information
    GitolitePublicKey.all.each do |p|
      delete_when_unused_temp = p.delete_when_unused == 1
      say 'Update!'
      p.update_column(:delete_when_unused_temp, delete_when_unused_temp)
    end
    remove_column :gitolite_public_keys, :delete_when_unused
    rename_column :gitolite_public_keys, :delete_when_unused_temp, :delete_when_unused

    ## RepositoryGitExtra
    add_column :repository_git_extras, :git_daemon_temp, :boolean, default: true, after: :git_daemon
    RepositoryGitExtra.reset_column_information
    RepositoryGitExtra.all.each do |p|
      git_daemon_temp = p.git_daemon == 1
      say 'Update!'
      p.update_column(:git_daemon_temp, git_daemon_temp)
    end
    remove_column :repository_git_extras, :git_daemon
    rename_column :repository_git_extras, :git_daemon_temp, :git_daemon

    add_column :repository_git_extras, :git_notify_temp, :boolean, default: true, after: :git_notify
    RepositoryGitExtra.reset_column_information
    RepositoryGitExtra.all.each do |p|
      git_notify_temp = p.git_notify == 1
      say 'Update!'
      p.update_column(:git_notify_temp, git_notify_temp)
    end
    remove_column :repository_git_extras, :git_notify
    rename_column :repository_git_extras, :git_notify_temp, :git_notify

    ## RepositoryDeploymentCredential
    add_column :repository_deployment_credentials, :active_temp, :boolean, default: true, after: :active
    RepositoryDeploymentCredential.reset_column_information
    RepositoryDeploymentCredential.all.each do |p|
      active_temp = p.active == 1
      say 'Update!'
      p.update_column(:active_temp, active_temp)
    end
    remove_column :repository_deployment_credentials, :active
    rename_column :repository_deployment_credentials, :active_temp, :active

    ## RepositoryMirror
    add_column :repository_mirrors, :active_temp, :boolean, default: true, after: :active
    RepositoryMirror.reset_column_information
    RepositoryMirror.all.each do |p|
      active_temp = p.active == 1
      say 'Update!'
      p.update_column(:active_temp, active_temp)
    end
    remove_column :repository_mirrors, :active
    rename_column :repository_mirrors, :active_temp, :active

    ## RepositoryPostReceiveUrl
    add_column :repository_post_receive_urls, :active_temp, :boolean, default: true, after: :active
    RepositoryPostReceiveUrl.reset_column_information
    RepositoryPostReceiveUrl.all.each do |p|
      active_temp = p.active == 1
      say 'Update!'
      p.update_column(:active_temp, active_temp)
    end
    remove_column :repository_post_receive_urls, :active
    rename_column :repository_post_receive_urls, :active_temp, :active
  end
end
