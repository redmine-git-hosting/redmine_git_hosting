# frozen_string_literal: true

class AddSettingsToPlugin5 < ActiveRecord::Migration[4.2]
  def up
    # Add some new settings to settings page, if they don't exist
    valuehash = Setting.plugin_redmine_git_hosting.clone
    valuehash['gitConfigFile'] ||= 'gitolite.conf'
    valuehash['gitConfigHasAdminKey'] ||= 'true'

    if Setting.plugin_redmine_git_hosting != valuehash
      say 'Added redmine_git_hosting settings: gitConfigFile, gitConfigHasAdminKey'
      Setting.plugin_redmine_git_hosting = valuehash
    end
  rescue StandardError => e
    say e.message
  end

  def down
    # Remove above settings from plugin page
    valuehash = Setting.plugin_redmine_git_hosting.clone
    valuehash.delete 'gitConfigFile'
    valuehash.delete 'gitConfigHasAdminKey'

    if Setting.plugin_redmine_git_hosting != valuehash
      say 'Removed redmine_git_hosting settings: gitConfigFile, gitConfigHasAdminKey'
      Setting.plugin_redmine_git_hosting = valuehash
    end
  rescue StandardError => e
    say e.message
  end
end
