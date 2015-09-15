class AddTriggerToPostReceive < ActiveRecord::Migration

  def self.up
    add_column :repository_post_receive_urls, :use_triggers, :boolean, default: false
    add_column :repository_post_receive_urls, :triggers,     :text
  end

  def self.down
    remove_column :repository_post_receive_urls, :use_triggers
    remove_column :repository_post_receive_urls, :triggers
  end

end
