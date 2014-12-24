namespace :redmine_git_hosting do

  desc "Reload defaults from init.rb into the redmine_git_hosting settings."
  task :restore_default_settings => [:environment] do
    puts "Reloading defaults from init.rb..."
    RedmineGitolite::GitHosting.logger.warn { "Reloading defaults from init.rb from command line" }
    RedmineGitolite::Config.reload_from_file!(console: true)
    puts "Done!"
  end
  task :restore_defaults => [ :restore_default_settings ]


  desc "Purge expired repositories from Recycle Bin"
  task :purge_recycle_bin => [:environment] do
    puts "Purging Recycle Bin..."
    RedmineGitolite::GitHosting.logger.warn { "Purging Recycle Bin from command line" }
    RedmineGitolite::Recycle.new().delete_expired_files
    puts "Done!"
  end


  desc "Update/repair Gitolite configuration"
  task :update_repositories => [:environment] do
    puts "Performing manual update_repositories operation..."
    RedmineGitolite::GitHosting.logger.warn { "Performing manual update_repositories operation from command line" }
    options = { message: "Resync all projects (#{projects.length})..." }
    UpdateProjects.new('all', options).call
    puts "Done!"
  end


  desc "Fetch commits from gitolite repositories/update gitolite configuration"
  task :fetch_changesets => [:environment] do
    puts "Performing manual fetch_changesets operation..."
    RedmineGitolite::GitHosting.logger.warn { "Performing manual fetch_changesets operation from command line" }
    Repository.fetch_changesets
    RedmineGitolite::GitHosting.logger.warn { "Done!" }
    puts "Done!"
  end


  desc "Check repositories identifier uniqueness"
  task :check_repository_uniqueness => [:environment] do
    puts "Checking repositories identifier uniqueness..."
    if Repository::Xitolite.have_duplicated_identifier?
      # Oops -- have duplication.
      RedmineGitolite::GitHosting.logger.error { "Detected non-unique repository identifiers!" }
      puts "Detected non-unique repository identifiers!"
    else
      puts "pass!"
    end
    puts "Done!"
  end


  desc "Install/update Gitolite hooks"
  task :install_hook_files => [:environment] do
    puts ""
    puts "Installing/updating Gitolite hooks"
    puts "----------------------------------"
    puts "Results :"
    result = RedmineGitolite::HookManager.check_install!
    puts YAML::dump(result)
    puts "Done!"
  end


  desc "Install/update Gitolite hook parameters"
  task :install_hook_parameters => [:environment] do
    puts ""
    puts "Installing/updating Gitolite hook parameters"
    puts "----------------------------------"
    puts "Results :"
    result = RedmineGitolite::HookManager.update_hook_params!
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
