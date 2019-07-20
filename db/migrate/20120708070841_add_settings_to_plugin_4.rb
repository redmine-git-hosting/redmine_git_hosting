class AddSettingsToPlugin4 < ActiveRecord::Migration[4.2]
  def up
    # Add some new settings to settings page, if they don't exist
    valuehash = Setting.plugin_redmine_git_hosting.clone
    valuehash['gitForceHooksUpdate'] ||= 'true'

    if Setting.plugin_redmine_git_hosting != valuehash
      say 'Added redmine_git_hosting settings: gitForceHooksUpdate'
      Setting.plugin_redmine_git_hosting = valuehash
    end
  rescue => e
    say e.message
  end

  def down
    # Remove above settings from plugin page
    valuehash = Setting.plugin_redmine_git_hosting.clone
    valuehash.delete('gitForceHooksUpdate')

    if Setting.plugin_redmine_git_hosting != valuehash
      say 'Removed redmine_git_hosting settings: gitForceHooksUpdate'
      Setting.plugin_redmine_git_hosting = valuehash
    end
  rescue => e
    say e.message
  end
end
