class AddUniqueIndexToFingerprint < ActiveRecord::Migration

  def self.up
    add_index :gitolite_public_keys, :fingerprint, unique: true
  end

  def self.down
    remove_index :gitolite_public_keys, :fingerprint
  end

end
