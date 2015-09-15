class AddSplitPayloadsToPostReceive < ActiveRecord::Migration

  def self.up
    add_column :repository_post_receive_urls, :split_payloads, :boolean, default: false
  end

  def self.down
    remove_column :repository_post_receive_urls, :split_payloads
  end

end
