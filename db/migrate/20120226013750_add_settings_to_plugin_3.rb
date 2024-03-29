# frozen_string_literal: true

class AddSettingsToPlugin3 < ActiveRecord::Migration[4.2]
  def up
    # Add some new settings to settings page, if they don't exist
    valuehash = Setting.plugin_redmine_git_hosting.clone
    valuehash['gitDaemonDefault'] ||= '1'
    valuehash['gitHttpDefault'] ||= '1'
    valuehash['gitNotifyCIADefault'] ||= '0'
    valuehash['gitTempDataDir'] ||= '/tmp/redmine_git_hosting/'
    valuehash['gitScriptDir'] ||= ''

    if Setting.plugin_redmine_git_hosting != valuehash
      say 'Added redmine_git_hosting settings: gitDaemonDefault, gitHttpDefault, gitNotifyCIADefault, gitTempDataDir, gitScriptDir'

      if Setting.plugin_redmine_git_hosting['httpServer'] != valuehash['httpServer']
        say "Updated 'httpServer' from '#{Setting.plugin_redmine_git_hosting['httpServer']}' to '#{valuehash['httpServer']}'."
      end

      Setting.plugin_redmine_git_hosting = valuehash
    end
  rescue StandardError => e
    say e.message
  end

  def down
    # Remove above settings from plugin page
    valuehash = Setting.plugin_redmine_git_hosting.clone
    valuehash.delete 'gitDaemonDefault'
    valuehash.delete 'gitHttpDefault'
    valuehash.delete 'gitNotifyDIADefault'
    valuehash.delete 'gitTempDataDir'
    valuehash.delete 'gitScriptDir'

    if Setting.plugin_redmine_git_hosting != valuehash
      say 'Removed redmine_git_hosting settings: gitDaemonDefault, gitHttpDefault, gitNotifyCIADefault, gitTempDataDir, gitScriptDir'
      Setting.plugin_redmine_git_hosting = valuehash
    end
  rescue StandardError => e
    say e.message
  end
end
