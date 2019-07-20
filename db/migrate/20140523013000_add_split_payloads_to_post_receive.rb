class AddSplitPayloadsToPostReceive < ActiveRecord::Migration[4.2]
  def change
    add_column :repository_post_receive_urls, :split_payloads, :boolean, default: false
  end
end
