class AddFingerprintToGitolitePublicKeys < ActiveRecord::Migration

  def self.up
    add_column :gitolite_public_keys, :fingerprint, :string, :null => false, :after => 'key'
  end


  def self.down
    remove_column :gitolite_public_keys, :fingerprint
  end

end
