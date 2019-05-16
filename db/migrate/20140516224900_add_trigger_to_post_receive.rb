class AddTriggerToPostReceive < ActiveRecord::Migration[4.2]
  def change
    add_column :repository_post_receive_urls, :use_triggers, :boolean, default: false
    add_column :repository_post_receive_urls, :triggers, :text
  end
end
