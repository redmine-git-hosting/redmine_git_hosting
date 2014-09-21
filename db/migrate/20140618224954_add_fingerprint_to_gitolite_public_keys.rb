class AddFingerprintToGitolitePublicKeys < ActiveRecord::Migration

  def self.up
    add_column :gitolite_public_keys, :fingerprint, :string, :after => 'key'
    GitolitePublicKey.update_all("fingerprint = ''")
    change_column :gitolite_public_keys, :fingerprint, :string, :null => false
  end


  def self.down
    remove_column :gitolite_public_keys, :fingerprint
  end

end
