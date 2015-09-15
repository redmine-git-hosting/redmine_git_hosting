class RemoveGitolitePublicKeysActiveColumn < ActiveRecord::Migration

  def self.up
    remove_column :gitolite_public_keys, :active
  end

  def self.down
    add_column :gitolite_public_keys, :active, :boolean, default: true, after: :fingerprint
  end

end
