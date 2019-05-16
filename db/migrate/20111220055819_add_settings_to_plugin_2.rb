class AddSettingsToPlugin2 < ActiveRecord::Migration[4.2]
  def up
    # Add some new settings to settings page, if they don't exist
    valuehash = Setting.plugin_redmine_git_hosting.clone
    valuehash['httpServerSubdir'] ||= ''
    valuehash['gitRedmineSubdir'] ||= ''
    valuehash['gitRepositoryHierarchy'] ||= 'true'

    # Fix httpServer by removing directory components
    valuehash['httpServer'] = (valuehash['httpServer'][%r{^[^\/]*}])

    if Setting.plugin_redmine_git_hosting != valuehash
      say 'Added redmine_git_hosting settings: httpServerSubdir, gitRedmineSubdir, gitRepositoryHierarchy'

      if Setting.plugin_redmine_git_hosting['httpServer'] != valuehash['httpServer']
        say "Updated 'httpServer' from '#{Setting.plugin_redmine_git_hosting['httpServer']}' to '#{valuehash['httpServer']}'."
      end

      Setting.plugin_redmine_git_hosting = valuehash
    end
  rescue => e
    say e.message
  end

  def down
    # Remove above settings from plugin page
    valuehash = Setting.plugin_redmine_git_hosting.clone
    valuehash.delete('httpServerSubdir')
    valuehash.delete('gitRedmineSubdir')
    valuehash.delete('gitRepositoryHierarchy')

    # Restore redmine root directory to httpServer (remove trailing '/')
    valuehash['httpServer'] = RedmineGitHosting::Config.my_root_url

    if Setting.plugin_redmine_git_hosting != valuehash
      say 'Removed redmine_git_hosting settings: httpServerSubdir, gitRedmineSubdir, gitRepositoryHierarchy'

      if Setting.plugin_redmine_git_hosting['httpServer'] != valuehash['httpServer']
        say "Updated 'httpServer' from '#{Setting.plugin_redmine_git_hosting['httpServer']}' to '#{valuehash['httpServer']}'."
      end

      Setting.plugin_redmine_git_hosting = valuehash
    end
  rescue => e
    say e.message
  end
end
