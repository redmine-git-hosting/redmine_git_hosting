class AddSettingsToPlugin < ActiveRecord::Migration
  def self.up
    begin
      GitHostingObserver.set_update_active(false)

      # Add some new settings to settings page, if they don't exist
      valuehash = (Setting.plugin_redmine_git_hosting).clone
      valuehash['gitRecycleBasePath'] ||= 'recycle_bin/'
      valuehash['gitRecycleExpireTime'] ||= '24.0'
      valuehash['gitLockWaitTime'] ||= '10'
      valuehash['httpServer'] ||= GitHostingConf.my_root_url

      if (Setting.plugin_redmine_git_hosting != valuehash)
        Setting.plugin_redmine_git_hosting = valuehash
        say "Added redmine_git_hosting settings: 'gitRecycleBasePath', 'getRecycleExpireTime', 'getLockWaitTime', 'httpServer'"
      end
    rescue => e
      puts e.message
    end
  end

  def self.down
    begin
      GitHostingObserver.set_update_active(false)

      # Remove above settings from plugin page
      valuehash = (Setting.plugin_redmine_git_hosting).clone
      valuehash.delete('gitRecycleBasePath')
      valuehash.delete('gitRecycleExpireTime')
      valuehash.delete('gitLockWaitTime')
      valuehash.delete('gitLockWaitTime')

      if (Setting.plugin_redmine_git_hosting != valuehash)
        Setting.plugin_redmine_git_hosting = valuehash
        say "Removed redmine_git_hosting settings: 'gitRecycleBasePath', 'getRecycleExpireTime', 'getLockWaitTime', 'httpServer'"
      end
      Setting.plugin_redmine_git_hosting = valuehash
    rescue => e
      puts e.message
    end
  end
end
