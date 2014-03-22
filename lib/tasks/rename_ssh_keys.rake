namespace :redmine_git_hosting do

  desc "Rename SSH keys"
  task :rename_ssh_keys => [:environment] do

    puts ""
    puts "Delete SSH keys in Gitolite and reset identifier :"
    puts ""

    GitolitePublicKey.active.each do |ssh_key|
      repo_key = {}
      repo_key['title']    = ssh_key.identifier
      repo_key['key']      = ssh_key.key
      repo_key['owner']    = ssh_key.owner
      repo_key['location'] = ssh_key.location

      puts "  - Delete SSH key #{ssh_key.identifier}"
      RedmineGitolite::GitHosting.resync_gitolite({ :command => :delete_ssh_key, :object => repo_key })

      ssh_key.reset_identifier
    end
    puts ""

    puts "Add SSH keys with new name in Gitolite :"
    puts ""

    user_list = []
    GitolitePublicKey.active.each do |ssh_key|
      puts "  - Add SSH key : #{ssh_key.identifier}"
      user_list.push(ssh_key.user_id)
    end

    user_list.uniq.each do |user_id|
      RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_ssh_keys, :object => user_id })
    end
    puts ""

    puts "Update projects repositories permissions"
    projects = Project.active_or_archived.find(:all, :include => :repositories)
    if projects.length > 0
      RedmineGitolite::GitHosting.logger.info "Gitolite configuration has been modified, resync all projects..."
      RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_all_projects, :object => projects.length })
    end
    puts ""

  end

end
