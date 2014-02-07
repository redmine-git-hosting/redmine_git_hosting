module RedmineGitolite
  class Translations
    # Adds plugin locales if any
    # YAML translation files should be found under <plugin>/config/locales/
    ::I18n.load_path += Dir.glob(File.expand_path(File.join(File.join(Rails.root, 'plugins/redmine_git_hosting'), 'config', 'locales', '**', '*.yml')))
  end
end
