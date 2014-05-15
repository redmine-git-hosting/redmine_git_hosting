#
# Tasks in this namespace (redmine_git_hosting) are for administrative tasks
#
# TOP-LEVEL TARGETS:
#
# 1) Repopulate settings in the database with defaults from init.rb
#
# rake redmine_git_hosting:restore_defaults RAILS_ENV=xxx
#
# 2) Resynchronize/repair gitolite configuration (fix keys directory and configuration).
#    Also, expire repositories in the recycle_bin if necessary.
#
# rake redmine_git_hosting:update_repositories RAILS_ENV=xxx
#
# 3) Fetch all changesets for repositories and then rescynronize gitolite configuration (as in #1)
#
# rake redmine_git_hosting:fetch_changsets RAILS_ENV=xxx
#
# 4) Install custom scripts to the script directory.  The optional argument
#    'READ_ONLY=true' requests that the resulting scripts and script directory
#    be made read-only to the web server.  The optional argument WEB_USER=xxx
#    states that scripts should be owned by user "xxx".  If omitted, the
#    script attempts to figure out the web user by using "ps" and looking
#    for httpd.
#
# rake redmine_git_hosting:install_scripts [READ_ONLY=true] [WEB_USER=xxx] RAILS_ENV=yyy
#
# 5) Remove the custom scripts directory (and the enclosed scripts)
#
# rake redmine_git_hosting:remove_scripts RAILS_ENV=xxxx
#

namespace :redmine_git_hosting do

  desc "Reload defaults from init.rb into the redmine_git_hosting settings."
  task :restore_defaults => [:environment] do
    puts "Reloading defaults from init.rb..."
    RedmineGitolite::GitHosting.logger.warn { "Reloading defaults from init.rb from command line" }
    RedmineGitolite::ConfigRedmine.reload_config
    puts "Done!"
  end


  desc "Update/repair Gitolite configuration"
  task :update_repositories => [:environment] do
    puts "Performing manual update_repositories operation..."
    RedmineGitolite::GitHosting.logger.warn { "Performing manual update_repositories operation from command line" }

    projects = Project.active_or_archived.find(:all, :include => :repositories)
    if projects.length > 0
      RedmineGitolite::GitHosting.logger.info { "Resync all projects (#{projects.length})..." }
      RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_all_projects, :object => projects.length })
    end

    puts "Done!"
  end


  desc "Fetch commits from gitolite repositories/update gitolite configuration"
  task :fetch_changesets => [:environment] do
    puts "Performing manual fetch_changesets operation..."
    RedmineGitolite::GitHosting.logger.warn { "Performing manual fetch_changesets operation from command line" }
    Repository.fetch_changesets
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


  desc "Install redmine_git_hosting scripts"
  task :install_scripts do |t,args|
    if !ENV["READ_ONLY"]
      ENV["READ_ONLY"] = "false"
    end
    Rake::Task["selinux:redmine_git_hosting:install_scripts"].invoke
  end


  desc "Remove redmine_git_hosting scripts"
  task :remove_scripts do
    Rake::Task["selinux:redmine_git_hosting:remove_scripts"].invoke
  end


  desc "Show library version"
  task :version do
    puts "#{name} #{version}"
  end


  desc "Start unit tests"
  task :test => :default
  task :default do
    RSpec::Core::RakeTask.new(:spec) do |config|
      config.rspec_opts = "plugins/redmine_git_hosting/spec --color --format nested --fail-fast"
    end
    Rake::Task["spec"].invoke
  end


  desc "Start unit tests in JUnit format"
  task :test_junit do
    RSpec::Core::RakeTask.new(:spec) do |config|
      config.rspec_opts = "plugins/redmine_git_hosting/spec --format RspecJunitFormatter --out junit/rspec.xml"
    end
    Rake::Task["spec"].invoke
  end

end


# Produce date string of form used by redmine logs
def my_date
  Time.now.strftime("%Y-%m-%d %H:%M:%S")
end


def name
  "Redmine Git Hosting"
end


def version
  line = File.read(Rails.root.join("plugins/redmine_git_hosting/init.rb"))[/^\s*version\s*.*/]
  line.match(/.*version\s*['"](.*)['"]/)[1]
end
