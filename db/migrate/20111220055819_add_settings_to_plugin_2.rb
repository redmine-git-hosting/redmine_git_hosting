class AddSettingsToPlugin2 < ActiveRecord::Migration
  def self.up
    begin
      GitHostingObserver.set_update_active(false)

      # Add some new settings to settings page, if they don't exist
      valuehash = (Setting.plugin_redmine_git_hosting).clone
      valuehash['httpServerSubdir'] ||= ''
      valuehash['gitRedmineSubdir'] ||= ''
      valuehash['gitRepositoryHierarchy'] ||= 'true'

      # Fix httpServer by removing directory components
      valuehash['httpServer'] = (valuehash['httpServer'][/^[^\/]*/])

      if (Setting.plugin_redmine_git_hosting != valuehash)
        say "Added redmine_git_hosting settings: 'httpServerSubdir', 'gitRedmineSubdir', 'gitRepositoryHierarchy'"
        if (Setting.plugin_redmine_git_hosting['httpServer'] != valuehash['httpServer'])
          say "Updated 'httpServer' from '#{Setting.plugin_redmine_git_hosting['httpServer']}' to '#{valuehash['httpServer']}'."
        end
        Setting.plugin_redmine_git_hosting = valuehash
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
      valuehash.delete('httpServerSubdir')
      valuehash.delete('gitRedmineSubdir')
      valuehash.delete('gitRepositoryHierarchy')

      # Restore redmine root directory to httpServer (remove trailing '/')
      valuehash['httpServer'] = GitHostingConf.my_root_url

      if (Setting.plugin_redmine_git_hosting != valuehash)
        say "Removed redmine_git_hosting settings: 'httpServerSubdir', 'gitRedmineSubdir', 'gitRepositoryHierarchy'"
        if (Setting.plugin_redmine_git_hosting['httpServer'] != valuehash['httpServer'])
          say "Updated 'httpServer' from '#{Setting.plugin_redmine_git_hosting['httpServer']}' to '#{valuehash['httpServer']}'."
        end
        Setting.plugin_redmine_git_hosting = valuehash
      end
    rescue => e
      puts e.message
    end
  end
end
