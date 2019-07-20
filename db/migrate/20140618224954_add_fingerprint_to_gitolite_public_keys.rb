class AddFingerprintToGitolitePublicKeys < ActiveRecord::Migration[4.2]
  def change
    add_column :gitolite_public_keys, :fingerprint, :string, after: 'key'
  end
end
