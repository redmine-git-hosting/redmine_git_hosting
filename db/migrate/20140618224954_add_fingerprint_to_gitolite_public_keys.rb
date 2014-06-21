class AddFingerprintToGitolitePublicKeys < ActiveRecord::Migration

  def self.up
    add_column :gitolite_public_keys, :fingerprint, :string, :null => false, :after => 'key'
    add_index  :gitolite_public_keys, :fingerprint, :unique => true
  end


  def self.down
    remove_index  :gitolite_public_keys, :fingerprint
    remove_column :gitolite_public_keys, :fingerprint
  end

end
