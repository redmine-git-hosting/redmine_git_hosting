namespace :redmine_git_hosting do

  desc 'Update plugin settings in database (This will read settings from `<redmine_root>/redmine_git_hosting.yml` and `<plugin_root>/settings.yml`)'
  task update_settings: [:environment] do
    RedmineGitHosting::ConsoleLogger.title('Reloading settings from command line') do
      RedmineGitHosting::Config.reload_from_file!
    end
  end


  desc 'Dump plugin settings in console'
  task dump_settings: [:environment] do
    RedmineGitHosting::Config.dump_settings
  end


  desc 'Purge expired repositories from Recycle Bin'
  task purge_recycle_bin: [:environment] do
    RedmineGitHosting::ConsoleLogger.title('Purging Recycle Bin from command line') do
      RedmineGitHosting::GitoliteAccessor.purge_recycle_bin
    end
  end


  desc 'Update/repair Gitolite configuration'
  task update_repositories: [:environment] do
    RedmineGitHosting::ConsoleLogger.title('Performing manual update_repositories operation from command line') do
      RedmineGitHosting::GitoliteAccessor.update_projects('all', { message: "Resync all projects (#{Project.all.length})..." })
    end
  end


  desc 'Fetch commits from gitolite repositories/update gitolite configuration'
  task fetch_changesets: [:environment] do
    RedmineGitHosting::ConsoleLogger.title('Performing manual fetch_changesets operation from command line') do
      RedmineGitHosting::GitoliteAccessor.flush_git_cache
      Repository.fetch_changesets
    end
  end


  desc 'Check repositories identifier uniqueness'
  task check_repository_uniqueness: [:environment] do
    RedmineGitHosting::ConsoleLogger.title('Checking repositories identifier uniqueness...') do
      if Repository::Xitolite.have_duplicated_identifier?
        RedmineGitHosting::ConsoleLogger.warn('Detected non-unique repository identifiers!')
        puts YAML::dump(Repository::Xitolite.identifiers_to_hash.reject! { |k, v| v == 1 })
      else
        RedmineGitHosting::ConsoleLogger.info('No duplication detected, good !')
      end
    end
  end


  desc 'Resync ssh_keys'
  task resync_ssh_keys: [:environment] do
    RedmineGitHosting::ConsoleLogger.title('Performing manual resync_ssh_keys operation from command line') do
      RedmineGitHosting::GitoliteAccessor.resync_ssh_keys(bypass_sidekiq: true)
    end
  end


  desc 'Regenerate ssh_keys'
  task regenerate_ssh_keys: [:environment] do
    RedmineGitHosting::ConsoleLogger.title('Performing manual regenerate_ssh_keys operation from command line') do
      RedmineGitHosting::GitoliteAccessor.regenerate_ssh_keys(bypass_sidekiq: true)
    end
  end


  desc 'Install/update Gitolite hooks'
  task install_hook_files: [:environment] do
    RedmineGitHosting::ConsoleLogger.title('Installing/updating Gitolite hooks') do
      puts YAML::dump(RedmineGitHosting::Config.install_hooks!)
    end
  end


  desc 'Install/update Gitolite hook parameters'
  task install_hook_parameters: [:environment] do
    RedmineGitHosting::ConsoleLogger.title('Installing/updating Gitolite hook parameters') do
      puts YAML::dump(RedmineGitHosting::Config.update_hook_params!)
    end
  end

  task install_gitolite_hooks: [:install_hook_files, :install_hook_parameters]

  desc 'Show library version'
  task :version do
    puts "Redmine Git Hosting #{version("plugins/redmine_git_hosting/init.rb")}"
  end

  def version(path)
    line = File.read(Rails.root.join(path))[/^\s*version\s*.*/]
    line.match(/.*version\s*['"](.*)['"]/)[1]
  end

end
