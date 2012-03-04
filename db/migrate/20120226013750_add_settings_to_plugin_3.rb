class AddSettingsToPlugin3 < ActiveRecord::Migration
  def self.up
	begin
	  	# Add some new settings to settings page, if they don't exist
  		valuehash = (Setting.plugin_redmine_git_hosting).clone
        	valuehash['gitDaemonDefault'] ||= '1'
        	valuehash['gitHttpDefault'] ||= '1'
        	valuehash['gitNotifyCIADefault'] ||= '0'
  		valuehash['gitTempDataDir'] ||= '/tmp/redmine_git_hosting/'
        	valuehash['gitScriptDir'] ||= ''
          
        	if (Setting.plugin_redmine_git_hosting != valuehash)
                	say "Added redmine_git_hosting settings: 'gitDaemonDefault', 'gitHttpDefault', 'gitNotifyCIADefault', 'gitTempDataDir', 'gitScriptDir'"
                	if (Setting.plugin_redmine_git_hosting['httpServer'] != valuehash['httpServer'])
                        	say "Updated 'httpServer' from '#{Setting.plugin_redmine_git_hosting['httpServer']}' to '#{valuehash['httpServer']}'."
                        end
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
        	valuehash.delete('gitDaemonDefault')
        	valuehash.delete('gitHttpDefault')
        	valuehash.delete('gitNotifyDIADefault')
  		valuehash.delete('gitTempDataDir')
  		valuehash.delete('gitScriptDir')

        	if (Setting.plugin_redmine_git_hosting != valuehash)
                	say "Removed redmine_git_hosting settings: 'gitDaemonDefault', 'gitHttpDefault', 'gitNotifyCIADefault', 'gitTempDataDir', 'gitScriptDir'"
                	Setting.plugin_redmine_git_hosting = valuehash
                end
        rescue => e
        	# ignore problems if table doesn't exist yet....
        end
  end
end
