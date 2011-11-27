class AddSettingsToPlugin < ActiveRecord::Migration
  def self.up
	begin
	  	# Add some new settings to settings page, if they don't exist
  		valuehash = (Setting.plugin_redmine_git_hosting).clone
  		valuehash['gitRecycleBasePath'] ||= 'recycle_bin/'
  		valuehash['gitRecycleExpireTime'] ||= '24.0'
  		valuehash['gitLockWaitTime'] ||= '10'
        	if (Setting.plugin_redmine_git_hosting != valuehash)
                	Setting.plugin_redmine_git_hosting = valuehash
                	say "Added redmine_git_hosting settings: 'gitRecycleBasePath', 'getRecycleExpireTime', 'getLockWaitTime'"
                end
        rescue  
        	# ignore problems if plugin settings don't exist yet
        end
  end

  def self.down
  	begin
	  	# Remove above settings from plugin page
		valuehash = (Setting.plugin_redmine_git_hosting).clone
  		valuehash.delete('gitRecycleBasePath')
  		valuehash.delete('gitRecycleExpireTime')
  		valuehash.delete('gitLockWaitTime')
        	if (Setting.plugin_redmine_git_hosting != valuehash)
                	Setting.plugin_redmine_git_hosting = valuehash
                	say "Removed redmine_git_hosting settings: 'gitRecycleBasePath', 'getRecycleExpireTime', 'getLockWaitTime'"
                end
		Setting.plugin_redmine_git_hosting = valuehash
        rescue
        	# ignore problems if table doesn't exist yet....
        end
  end
end
