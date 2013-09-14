namespace :redmine do
  namespace :git_hosting do

    desc "Rename SSH keys"
    task :rename_ssh_keys => :environment do

      puts "Delete SSH keys in Gitolite and reset identifier"
      GitolitePublicKey.active.each do |ssh_key|
        repo_key = Hash.new
        repo_key[:title]    = ssh_key.identifier
        repo_key[:key]      = ssh_key.key
        repo_key[:owner]    = ssh_key.owner
        repo_key[:location] = ssh_key.location

        puts "Delete SSH key #{ssh_key.identifier}"
        GithostingShellWorker.perform_async({ :command => :delete_ssh_key, :object => repo_key })

        ssh_key.reset_identifier
        ssh_key.save!
      end
      puts ""

      puts "Add SSH keys with new name in Gitolite"
      user_list = []
      GitolitePublicKey.active.each do |ssh_key|
        user_list.push(ssh_key.user_id)
      end

      user_list.uniq.each do |user_id|
        GithostingShellWorker.perform_async({ :command => :update_ssh_keys, :object => user_id })
      end
      puts ""

      puts "Update projects repositories permissions"
      projects = Project.active_or_archived.find(:all, :include => :repositories)
      if projects.length > 0
        GitHosting.logger.info "Gitolite configuration has been modified, resync all projects..."
        GithostingShellWorker.perform_async({ :command => :update_all_projects, :object => projects.length })
      end
      puts ""

    end
  end
end
