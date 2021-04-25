# frozen_string_literal: true

class AddUniqueIndexToFingerprint < ActiveRecord::Migration[4.2]
  def change
    add_index :gitolite_public_keys, :fingerprint, unique: true
  end
end
