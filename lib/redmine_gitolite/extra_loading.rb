module RedmineGitolite
  module ExtraLoading
    # Adds plugin locales if any
    # YAML translation files should be found under <plugin>/config/locales/
    ::I18n.load_path += Dir.glob(Rails.root.join('plugins', 'redmine_git_hosting', 'config', 'locales', '**', '*.yml'))

    # Load Forms and Concerns objects
    [
      Rails.root.join('plugins', 'redmine_git_hosting', 'app', 'services'),
      Rails.root.join('plugins', 'redmine_git_hosting', 'app', 'use_cases')
    ].each do |dir|
      if Dir.exists?(dir)
        ActiveSupport::Dependencies.autoload_paths += [dir]
      end
    end

  end
end
