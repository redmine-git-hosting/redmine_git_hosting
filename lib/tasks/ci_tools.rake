namespace :redmine_git_hosting do
  namespace :ci do
    unless Rails.env.production?
      RSpec::Core::RakeTask.new do |task|
        task.rspec_opts = '--pattern plugins/redmine_git_hosting/spec/\*\*\{,/\*/\*\*\}/\*_spec.rb --color'
      end
    end

    desc 'Check unit tests results'
    task check_unit_tests_results: [:environment] do
      gitolite_admin_dir = RedmineGitHosting::Config.gitolite_admin_dir
      gitolite_temp_dir  = RedmineGitHosting::Config.gitolite_temp_dir

      puts '#####################'
      puts 'TESTS RESULTS'
      puts ''
      puts "gitolite_temp_dir  : #{gitolite_temp_dir}"
      puts "gitolite_admin_dir : #{gitolite_admin_dir}"
      puts ''

      ls_dir(gitolite_temp_dir)
      ls_dir("#{gitolite_temp_dir}/git")
      ls_dir("#{gitolite_temp_dir}/git/gitolite-admin.git")

      begin
        repo = Rugged::Repository.new(gitolite_admin_dir)
        puts "git repo work dir  : #{repo.workdir}"
        puts "git repo path      : #{repo.path}"
        puts ''
        puts 'GIT STATUS :'
        puts '------------'
        puts %x[ git --work-tree "#{repo.workdir}" --git-dir "#{repo.path}" status ]
        puts ''
        puts 'GIT LOG :'
        puts '---------'
        puts %x[ git --work-tree "#{repo.workdir}" --git-dir "#{repo.path}" log ]
      rescue => e
        puts 'Error while getting tests results'
        puts e.message
      end
    end

    task all: ['spec', 'check_unit_tests_results']

    def ls_dir(dir)
      puts "* ls -hal #{dir}"
      puts %x[ ls -hal "#{dir}" ]
      puts ''
    end
  end

  task default: 'redmine_git_hosting:ci:all'
  task rspec:   'redmine_git_hosting:ci:all'
  task test:    'redmine_git_hosting:ci:all'
end
