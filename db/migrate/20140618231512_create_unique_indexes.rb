class CreateUniqueIndexes < ActiveRecord::Migration

  def self.up
    add_index :repository_git_extras, :repository_id, unique: true

    add_index :repository_git_notifications, :repository_id, unique: true

    add_index :repository_git_config_keys,   :repository_id
    add_index :repository_git_config_keys,   [:key, :repository_id], unique: true

    add_index :repository_post_receive_urls, :repository_id
    add_index :repository_post_receive_urls, [:url, :repository_id], unique: true

    add_index :repository_mirrors,           :repository_id
    add_index :repository_mirrors,           [:url, :repository_id], unique: true

    add_index :repository_deployment_credentials, [:repository_id, :gitolite_public_key_id], unique: true, name: 'index_deployment_credentials_on_repo_id_and_public_key_id'

    add_index :gitolite_public_keys, [:title, :user_id], unique: true

    add_index :github_comments, [:github_id, :journal_id], unique: true
    add_index :github_issues, [:github_id, :issue_id], unique: true
  end

  def self.down
    remove_index :repository_git_extras, :repository_id

    remove_index :repository_git_notifications, :repository_id

    remove_index :repository_git_config_keys,   :repository_id
    remove_index :repository_git_config_keys,   [:key, :repository_id]

    remove_index :repository_post_receive_urls, :repository_id
    remove_index :repository_post_receive_urls, [:url, :repository_id]

    remove_index :repository_mirrors,           :repository_id
    remove_index :repository_mirrors,           [:url, :repository_id]

    remove_index :repository_deployment_credentials, name: 'index_deployment_credentials_on_repo_id_and_public_key_id'

    remove_index :gitolite_public_keys, [:title, :user_id]

    remove_index :github_comments, [:github_id, :journal_id]
    remove_index :github_issues, [:github_id, :issue_id]
  end

end
