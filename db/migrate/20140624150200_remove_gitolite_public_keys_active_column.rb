class RemoveGitolitePublicKeysActiveColumn < ActiveRecord::Migration[4.2]
  def up
    remove_column :gitolite_public_keys, :active
  end

  def down
    add_column :gitolite_public_keys, :active, :boolean, default: true, after: :fingerprint
  end
end
