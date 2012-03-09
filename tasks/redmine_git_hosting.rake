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
	puts "[Reloading defaults from init.rb:"
	default_hash = Redmine::Plugin.find("redmine_git_hosting").settings[:default]
	if default_hash.nil? || default_hash.empty?
	    puts "  No defaults specified in init.rb!"
	else
	    changes = 0
	    valuehash = (Setting.plugin_redmine_git_hosting).clone
	    default_hash.each do |key,value|
		if valuehash[key] != value
		    print "  Changing '#{key}': '#{valuehash[key]}' => '#{value}'\n"
		    valuehash[key] = value
	            changes += 1
		end
	    end
	    if changes == 0
		print "  No changes necessary.\n"
	    else
	        print "  Committing changes ... "
	        begin
	    	    Setting.plugin_redmine_git_hosting = valuehash
		    print "Success!\n"
	        rescue
	            print "Failure.\n"
	        end
	    end
	end
	puts "DONE.]"
    end

    desc "Update/repair gitolite configuration"
    task :update_repositories => [:environment] do
	GitHosting.update_repositories(:resync_all => true)
    end

    desc "Fetch commits from gitolite repositories/update gitolite configuration"
    task :fetch_changesets => [:environment] do
    	Repository.fetch_changesets
    end

    desc "Install redmine_git_hosting scripts"
    task :install_scripts, [:read_only] => [:environment] do |t,args|
        if !ENV["READ_ONLY"]
	    ENV["READ_ONLY"] = "false"
	end
    	Rake::Task["selinux:redmine_git_hosting:install_scripts"].invoke
    end	

    desc "Remove redmine_git_hosting scripts"
    task :remove_scripts do
    	Rake::Task["selinux:redmine_git_hosting:remove_scripts"].invoke
    end	
end
