namespace :redmine_git_hosting do

  namespace :migration_tools do

    task :delete_ssh_key => [:environment] do
      puts ""
      puts "Delete SSH keys in Gitolite (they will be recreated later)"
      puts ""

      GitolitePublicKey.all.each do |ssh_key|
        repo_key = {}
        repo_key['title']    = ssh_key.identifier
        repo_key['key']      = ssh_key.key
        repo_key['owner']    = ssh_key.owner
        repo_key['location'] = ssh_key.location

        puts "  - Delete SSH key #{ssh_key.identifier}"
        RedmineGitolite::GitHosting.resync_gitolite({ :command => :delete_ssh_key, :object => repo_key })
      end
      puts ""

    end

  end

  desc "Prepare migration to v1.0 version"
  task :prepare_migration_to_v1 => [:environment] do
    ## First step : delete SSH keys
    task('redmine_git_hosting:migration_tools:delete_ssh_key').invoke
  end

end
