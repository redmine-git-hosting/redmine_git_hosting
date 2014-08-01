namespace :redmine_git_hosting do

  desc "Rename SSH keys"
  task :rename_ssh_keys => [:environment] do

    puts ""
    puts "Delete SSH keys in Gitolite and reset identifier :"
    puts ""

    GitolitePublicKey.all.each do |ssh_key|
      puts "  - Delete SSH key #{ssh_key.identifier}"
      RedmineGitolite::GitHosting.resync_gitolite(:delete_ssh_key, ssh_key.to_yaml, bypass_sidekiq: true)
      ssh_key.reset_identifiers
    end
    puts ""

    puts "Add SSH keys with new name in Gitolite :"
    puts ""

    GitolitePublicKey.all.each do |ssh_key|
      puts "  - Add SSH key : #{ssh_key.identifier}"
      RedmineGitolite::GitHosting.resync_gitolite(:add_ssh_key, ssh_key.id, bypass_sidekiq: true)
    end

    puts ""

    RedmineGitolite::GitHosting.logger.info "Gitolite configuration has been modified, resync all projects..."
    RedmineGitolite::GitHosting.resync_gitolite(:update_projects, 'all', bypass_sidekiq: true)

    puts "Done!"
  end

end
