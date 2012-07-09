class AddSettingsToPlugin4 < ActiveRecord::Migration
  def self.up
	begin
	  	# Add some new settings to settings page, if they don't exist
  		valuehash = (Setting.plugin_redmine_git_hosting).clone
        	valuehash['gitForceHooksUpdate'] ||= 'true'
        	if (Setting.plugin_redmine_git_hosting != valuehash)
                	say "Added redmine_git_hosting settings: 'gitForceHooksUpdate'."
                	Setting.plugin_redmine_git_hosting = valuehash
                end
        rescue => e
        	# ignore problems if plugin settings don't exist yet
        end
  end

  def self.down
  	begin
	  	# Remove above settings from plugin page
		valuehash = (Setting.plugin_redmine_git_hosting).clone
        	valuehash.delete('gitForceHooksUpdate')

        	if (Setting.plugin_redmine_git_hosting != valuehash)
                	say "Removed redmine_git_hosting settings: 'gitForceHooksUpdate'."
                	Setting.plugin_redmine_git_hosting = valuehash
                end
        rescue => e
        	# ignore problems if table doesn't exist yet....
        end
  end
end
