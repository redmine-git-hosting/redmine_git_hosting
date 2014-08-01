namespace :redmine_git_hosting do

  desc "Fix migration numbers (add missing trailing 0 to some migrations)"
  task :fix_migration_numbers => [:environment] do
    puts

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
          puts "Already migrated, pass!"
          puts
        end
        next
      end
      puts
    end

    puts "Done!"
  end
end
