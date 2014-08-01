# require 'rspec'
# require 'rspec/core/rake_task'

namespace :redmine_git_hosting do

  desc "Reload defaults from init.rb into the redmine_git_hosting settings."
  task :restore_default_settings => [:environment] do
    puts "Reloading defaults from init.rb..."
    RedmineGitolite::GitHosting.logger.warn { "Reloading defaults from init.rb from command line" }
    RedmineGitolite::Config.reload!
    puts "Done!"
  end


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
    RedmineGitolite::GitHosting.logger.info { "Resync all projects (#{projects.length})..." }
    RedmineGitolite::GitHosting.resync_gitolite(:update_projects, 'all')
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
    if Repository::Git.have_duplicated_identifier?
      # Oops -- have duplication.
      RedmineGitolite::GitHosting.logger.error { "Detected non-unique repository identifiers!" }
      puts "Detected non-unique repository identifiers!"
    else
      puts "pass!"
    end
    puts "Done!"
  end


  desc "Show library version"
  task :version do
    puts "Redmine Git Hosting #{version("plugins/redmine_git_hosting/init.rb")}"
  end


  desc "Start unit tests"
  task :test => :default
  task :default => [:environment] do
    RSpec::Core::RakeTask.new(:spec) do |config|
      config.rspec_opts = "plugins/redmine_git_hosting/spec --color"
    end
    Rake::Task["spec"].invoke
    Rake::Task["redmine_git_hosting:check_unit_tests_results"].invoke
  end


  desc "Start unit tests in JUnit format"
  task :test_junit => [:environment] do
    RSpec::Core::RakeTask.new(:spec) do |config|
      config.rspec_opts = "plugins/redmine_git_hosting/spec --format RspecJunitFormatter --out junit/rspec.xml"
    end
    Rake::Task["spec"].invoke
  end


  desc "Check unit tests results"
  task :check_unit_tests_results => [:environment] do
    gitolite_admin_dir = RedmineGitolite::GitoliteWrapper.gitolite_admin_dir
    gitolite_temp_dir  = RedmineGitolite::Config.get_setting(:gitolite_temp_dir)

    puts "#####################"
    puts "TESTS RESULTS"
    puts ""
    puts "gitolite_temp_dir  : #{gitolite_temp_dir}"
    puts "gitolite_admin_dir : #{gitolite_admin_dir}"
    puts ""

    puts "* ls -hal #{gitolite_temp_dir}"
    puts %x[ ls -hal #{gitolite_temp_dir} ]
    puts ""

    puts "* ls -hal #{gitolite_temp_dir}git"
    puts %x[ ls -hal #{gitolite_temp_dir}git ]
    puts ""

    puts "* ls -hal #{gitolite_temp_dir}git/gitolite-admin.git"
    puts %x[ ls -hal #{gitolite_temp_dir}git/gitolite-admin.git ]
    puts ""

    begin
      repo = Rugged::Repository.new(gitolite_admin_dir)
      puts "git repo work dir  : #{repo.workdir}"
      puts "git repo path      : #{repo.path}"
      puts ""
      puts "GIT STATUS :"
      puts "------------"
      puts %x[ git --work-tree #{repo.workdir} --git-dir #{repo.path} status ]
      puts ""
      puts "GIT LOG :"
      puts "---------"
      puts %x[ git --work-tree #{repo.workdir} --git-dir #{repo.path} log ]
    rescue => e
      puts "Error while getting tests results"
      puts e.message
    end
  end


  def version(path)
    line = File.read(Rails.root.join(path))[/^\s*version\s*.*/]
    line.match(/.*version\s*['"](.*)['"]/)[1]
  end

end
