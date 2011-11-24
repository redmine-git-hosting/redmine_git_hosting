class AddIndexesToGitolitePublicKey < ActiveRecord::Migration
  def self.up
    add_index :gitolite_public_keys, :user_id
    add_index :gitolite_public_keys, :identifier
  end

  def self.down
    remove_index :gitolite_public_keys, :user_id
    remove_index :gitolite_public_keys, :identifier
  end
end
