class AddFingerprintToGitolitePublicKeys < ActiveRecord::Migration

  def self.up
    add_column :gitolite_public_keys, :fingerprint, :string, :after => 'key'
    say_with_time 'Reset identifiers in exists repositories' do
       GitolitePublicKey.all.each do |key|
         key.reset_identifiers
       end
    end
    change_column :gitolite_public_keys, :fingeprint, :string, :null => false
  end


  def self.down
    remove_column :gitolite_public_keys, :fingerprint
  end

end
