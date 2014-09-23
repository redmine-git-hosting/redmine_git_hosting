namespace :redmine_git_hosting do

  namespace :ci do
    begin
      require 'ci/reporter/rake/rspec'

      RSpec::Core::RakeTask.new do |task|
        task.rspec_opts = "plugins/redmine_git_hosting/spec --color"
      end
    rescue Exception => e
    else
      ENV["CI_REPORTS"] = Rails.root.join('junit').to_s
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

    task :all => ['ci:setup:rspec', 'spec', 'check_unit_tests_results']
  end


  task :default => "redmine_git_hosting:ci:all"
  task :spec    => "redmine_git_hosting:ci:all"
  task :rspec   => "redmine_git_hosting:ci:all"
  task :test    => "redmine_git_hosting:ci:all"

end
