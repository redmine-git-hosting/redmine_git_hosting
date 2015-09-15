namespace :redmine_git_hosting do

  desc "Reload defaults from init.rb into the redmine_git_hosting settings."
  task :restore_default_settings => [:environment] do
    puts "Reloading defaults from init.rb..."
    RedmineGitHosting.logger.warn("Reloading defaults from init.rb from command line")
    RedmineGitHosting::Config.reload_from_file!(console: true)
    puts "Done!"
  end
  task :restore_defaults => [ :restore_default_settings ]


  desc "Purge expired repositories from Recycle Bin"
  task :purge_recycle_bin => [:environment] do
    puts "Purging Recycle Bin..."
    RedmineGitHosting.logger.warn("Purging Recycle Bin from command line")
    RedmineGitHosting::RecycleBin.delete_expired_content
    puts "Done!"
  end


  desc "Update/repair Gitolite configuration"
  task :update_repositories => [:environment] do
    puts "Performing manual update_repositories operation..."
    RedmineGitHosting.logger.warn("Performing manual update_repositories operation from command line")
    GitoliteAccessor.update_projects('all', { message: "Resync all projects (#{Project.all.length})..." })
    puts "Done!"
  end


  desc "Fetch commits from gitolite repositories/update gitolite configuration"
  task :fetch_changesets => [:environment] do
    puts "Performing manual fetch_changesets operation..."
    RedmineGitHosting.logger.warn("Performing manual fetch_changesets operation from command line")
    GitoliteAccessor.flush_git_cache
    Repository.fetch_changesets
    RedmineGitHosting.logger.warn("Done!")
    puts "Done!"
  end


  desc "Check repositories identifier uniqueness"
  task :check_repository_uniqueness => [:environment] do
    puts "Checking repositories identifier uniqueness..."
    if Repository::Xitolite.have_duplicated_identifier?
      # Oops -- have duplication.
      RedmineGitHosting.logger.error("Detected non-unique repository identifiers!")
      puts "Detected non-unique repository identifiers!"
      puts YAML::dump(Repository::Xitolite.identifiers_to_hash.reject! { |k, v| v == 1 })
    else
      puts "No duplication detected, good !"
    end
    puts ""
  end


  desc "Resync ssh_keys"
  task :resync_ssh_keys => [:environment] do
    puts "Performing manual resync_ssh_keys operation..."
    RedmineGitHosting.logger.warn("Performing manual resync_ssh_keys operation from command line")
    GitoliteAccessor.resync_ssh_keys(bypass_sidekiq: true)
    puts "Done!"
  end


  desc "Regenerate ssh_keys"
  task :regenerate_ssh_keys => [:environment] do
    puts "Performing manual regenerate_ssh_keys operation..."
    RedmineGitHosting.logger.warn("Performing manual regenerate_ssh_keys operation from command line")
    GitoliteAccessor.regenerate_ssh_keys(bypass_sidekiq: true)
    puts "Done!"
  end


  desc "Install/update Gitolite hooks"
  task :install_hook_files => [:environment] do
    puts ""
    puts "Installing/updating Gitolite hooks"
    puts "----------------------------------"
    puts "Results :"
    result = RedmineGitHosting::Config.install_hooks!
    puts YAML::dump(result)
    puts "Done!"
  end


  desc "Install/update Gitolite hook parameters"
  task :install_hook_parameters => [:environment] do
    puts ""
    puts "Installing/updating Gitolite hook parameters"
    puts "--------------------------------------------"
    puts "Results :"
    result = RedmineGitHosting::Config.update_hook_params!
    puts YAML::dump(result)
    puts "Done!"
  end

  task :install_gitolite_hooks => [ :install_hook_files, :install_hook_parameters ]

  desc "Show library version"
  task :version do
    puts "Redmine Git Hosting #{version("plugins/redmine_git_hosting/init.rb")}"
  end

  def version(path)
    line = File.read(Rails.root.join(path))[/^\s*version\s*.*/]
    line.match(/.*version\s*['"](.*)['"]/)[1]
  end

end
