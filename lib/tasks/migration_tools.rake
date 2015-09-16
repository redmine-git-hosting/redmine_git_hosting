namespace :redmine_git_hosting do

  namespace :migration_tools do

    desc 'Fix migration numbers (add missing trailing 0 to some migrations)'
    task fix_migration_numbers: [:environment] do
      puts ''

      %w[2011072600000 2011080700000 2011081300000 2011081700000 2012052100000 2012052100001 2012052200000].each do |migration|

        old_name = "#{migration}-redmine_git_hosting"
        new_name = "#{migration}0-redmine_git_hosting"
        puts "old_name : #{old_name}"
        puts "new_name : #{new_name}"

        # Get the old migration name
        query  = "SELECT * FROM #{ActiveRecord::Base.connection.quote_string('schema_migrations')} WHERE #{ActiveRecord::Base.connection.quote_string('version')} = '#{ActiveRecord::Base.connection.quote_string(old_name)}';"
        result = ActiveRecord::Base.connection.execute(query)

        # If present, rename
        if !result.to_a.empty?
          query = "DELETE FROM #{ActiveRecord::Base.connection.quote_string('schema_migrations')} WHERE #{ActiveRecord::Base.connection.quote_string('version')} = '#{ActiveRecord::Base.connection.quote_string(old_name)}';"
          ActiveRecord::Base.connection.execute(query)

          query = "INSERT INTO #{ActiveRecord::Base.connection.quote_string('schema_migrations')} (VERSION) VALUES ('#{ActiveRecord::Base.connection.quote_string(new_name)}');"
          ActiveRecord::Base.connection.execute(query)
        else
          # Check the new name is present
          query  = "SELECT * FROM #{ActiveRecord::Base.connection.quote_string('schema_migrations')} WHERE #{ActiveRecord::Base.connection.quote_string('version')} = '#{ActiveRecord::Base.connection.quote_string(new_name)}';"
          result = ActiveRecord::Base.connection.execute(query)

          if result.to_a.empty?
            puts "Error : migration is missing #{new_name}"
          else
            puts 'Already migrated, pass!'
            puts ''
          end
          next
        end
        puts ''
      end

      puts 'Done!'
    end


    desc 'Rename SSH keys'
    task rename_ssh_keys: [:environment] do

      puts ''
      puts 'Delete SSH keys in Gitolite and reset identifier :'
      puts ''

      GitolitePublicKey.all.each do |ssh_key|
        puts "  - Delete SSH key #{ssh_key.identifier}"
        RedmineGitHosting::GitoliteAccessor.destroy_ssh_key(ssh_key, bypass_sidekiq: true)
        ssh_key.reset_identifiers
      end
      puts ''

      puts 'Add SSH keys with new name in Gitolite :'
      puts ''

      GitolitePublicKey.all.each do |ssh_key|
        puts "  - Add SSH key : #{ssh_key.identifier}"
        RedmineGitHosting::GitoliteAccessor.create_ssh_key(ssh_key, bypass_sidekiq: true)
      end

      puts ''

      options = { message: 'Gitolite configuration has been modified, resync all projects...', bypass_sidekiq: true }
      RedmineGitHosting::GitoliteAccessor.update_projects('all', options)

      puts 'Done!'
    end


    desc 'Update repositories type (from Git to Xitolite)'
    task update_repositories_type: [:environment] do

      puts ''
      puts 'Update repositories type (from Git to Xitolite) :'
      puts ''

      Repository::Git.all.each do |repository|
        # Don't update real Git repositories
        next if repository.url.start_with?('/')

        # Don't update orphan repositories
        if repository.project.nil?
          puts "Repository with id : '#{repository.id}' doesn't have a project, skipping !!"
          puts ''
          next
        end

        # Update Gitolite repositories
        if repository.identifier.nil? || repository.identifier.empty?
          puts repository.project.identifier
          repository.update_attribute(:type, 'Repository::Xitolite')
          puts 'Done!'
          puts ''
        else
          puts repository.identifier
          repository.update_attribute(:type, 'Repository::Xitolite')
          puts 'Done!'
          puts ''
        end
      end
    end


    desc 'Check GitExtras presence'
    task check_git_extras_presence: [:environment] do

      puts ''
      puts 'Checking for GitExtras presence'
      puts ''

      Repository::Xitolite.all.each do |repository|
        if repository.project.nil?
          puts " - ERROR : Repository with id '##{repository.id}' has no associated project ! You should take a look at it !"
          puts ''
          next
        elsif !repository.extra.nil?
          puts " - Repository '#{repository.redmine_name}' has an entry in RepositoryGitExtras table, update it :"
          repository.extra.save!
        else
          puts " - Repository '#{repository.redmine_name}' has no entry in RepositoryGitExtras table, create it :"
          default_extra_options = {
            git_http:       RedmineGitHosting::Config.gitolite_http_by_default?,
            git_daemon:     RedmineGitHosting::Config.gitolite_daemon_by_default?,
            git_notify:     RedmineGitHosting::Config.gitolite_notify_by_default?,
            git_annex:      false,
            default_branch: 'master',
            key:            RedmineGitHosting::Utils::Crypto.generate_secret(64)
          }
          extra = repository.build_extra(default_extra_options)
          extra.save!
        end
        puts '   Done!'
        puts ''
      end

      puts 'Done!'
    end

  end


  desc 'Migrate to v1.0 version'
  task migrate_to_v1: [:environment] do
    ## First step : rename migrations in DB
    task('redmine_git_hosting:migration_tools:fix_migration_numbers').invoke
    ## Migrate DB only for redmine_git_hosting plugin
    ENV['NAME'] = 'redmine_git_hosting'
    task('redmine:plugins:migrate').invoke
    ## Rename SSH keys (reset identifier)
    task('redmine_git_hosting:migration_tools:rename_ssh_keys').invoke
    ## Update repositories type
    task('redmine_git_hosting:migration_tools:update_repositories_type').invoke
  end

end
