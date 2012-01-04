################################################################################
# Rakefile for selinux installation for Redmine+Redmine_Git_Hosting Plugin     #
#                                                                              #
# This rakefile provides a variety of options for configuring the selinux      #
# context for Redmine + Redmine_Git_Hosting Plugin.  In addition to the usual  #
# environment variables (such as RAIL_ENV), this rakefile has one additional   #
# variable, ROOT_PATTERN.  ROOT_PATTERN holds an optional regular expression   #
# (not globbed filename) which describes the possible root locations for       #
# redmine installations; note that such patterns must be quoted to avoid       #
# attempts by the shell to expand them.  If undefined, the rakefile will use   #
# the Rails.root for the local installation.                                   #
#                                                                              #
# TOP-LEVEL TARGETS:                                                           #
#                                                                              #
# These commands should be executed after altering the init.rb file as         #
# described in the README.mkb file.  Each target type comes in both "install"  #
# and "remove" versions. In the following, the environment variables are       #
# optional (of course). Default for ROOT_PATTERN is Rails.root                 #
#                                                                              #
# 1) Build bin directory with customized scripts for redmine_git_hosting,      #
#    install new selinux policy, and install complete selinux context for      #
#    redmine+redmine_git_hosting plugin                                        #
#                                                                              #
# rake selinux:install RAILS_ENV=xxx ROOT_PATTERN="yyy"                        #
# rake selinux:remove RAILS_ENV=xxx ROOT_PATTERN="yyy"                         #
#                                                                              #
# 2) Build bin directory with customized scripts for redmine_git_hosting,      #
#    install new selinux policy, and install selinux context for               #
#    redmine_git_hosting plugin (not for complete redmine installation). This  #
#    option assumes that the redmine installation (and plugin) code are        #
#    already labeled as "public_content_rw_t" except for dispatch.* files      #
#    which should be labeled as "httpd_sys_script_exec_t".                     #
#                                                                              #
# rake selinux:redmine_git_hosting:install RAILS_ENV=xxx ROOT_PATTERN="yyy"    #
# rake selinux:redmine_git_hosting:remove RAILS_ENV=xxx ROOT_PATTERN="yyy"     #
#                                                                              #
# 3) Build bin directory with customized scripts for redmine_git_hosting and   #
#    install new selinux policy. Do not install file contexts of any sort.     #
#    Proper labeling (done in some other way) should have all of redmine       #
#    (including plugins) labeled as "public_content_rw_t", with the exception  #
#    of public/dispatch.* (which should be labeled "httpd_sys_script_exec_t")  #
#    and vendor/plugins/redmine_git_hosting/bin(/.*) which should be labeled   #
#    with the new label "httpd_redmine_git_script_exec_t".                     #
#                                                                              #
# rake selinux:redmine_git_hosting:install_scripts_and_policy RAILS_ENV=xxx ROOT_PATTERN="yyy" 
# rake selinux:redmine_git_hosting:remove_scripts_and_policy RAILS_ENV=xxx ROOT_PATTERN="yyy"  
#                                                                              #
################################################################################

namespace :selinux do
    desc "Configure selinux for Redmine and Redmine_Git_Hosting plugin"
    task :install => [:environment,:install_contexts,"selinux:redmine_git_hosting:install"] do
    end

    desc "Unconfigure selinux for Redmine and Redmine_Git_Hosting plugin"
    task :remove => [:environment,"selinux:redmine_git_hosting:remove",:remove_contexts] do
    end

    desc "Install selinux file contexts for redmine (without plugins)"
    task :install_contexts => [:environment] do
        roots = redmine_roots
        root_pattern = redmine_root_pattern
        puts "[Installing file contexts for redmine:"

        sh "semanage fcontext -a -t public_content_rw_t \"#{root_pattern}(/.*)?\""
        sh "semanage fcontext -a -t httpd_sys_script_exec_t \"#{root_pattern}/public/dispatch.*\""

        roots.each do |path|
            puts "Setting new context for redmine root instance at #{path}."
            sh "restorecon -R -p #{path}"
        end
        puts "DONE.]"
    end

    desc "Remove selinux file contexts for redmine (without plugins)"
    task :remove_contexts => [:environment] do
        roots = redmine_roots
        root_pattern = redmine_root_pattern
        puts "[Removing file contexts for redmine (ignoring errors):"

        sh "semanage fcontext -d \"#{root_pattern}(/.*)?\""
        sh "semanage fcontext -d \"#{root_pattern}/public/dispatch.*\""

        roots.each do |path|
            puts "Setting new context for redmine root instance at #{path}."
            sh "restorecon -R -p #{path}"
        end
        puts "DONE.]"
    end

    namespace :redmine_git_hosting do
	desc "Install scripts, policy, and file context for redmine_git_hosting plugin."
	task :install => [:environment,:install_scripts,:install_policy,:install_contexts] do
	end
	    
	desc "Remove scripts, policy, and file context for redmine_git_hosting plugin."
        task :remove => [:environment,:remove_contexts,:remove_policy,:remove_scripts] do
	end
	 
	desc "Install scripts and policy for redmine_git_hosting plugin."
	task :install_scripts_and_policy => [:environment,:install_scripts,:install_policy] do
	end
	    
	desc "Remove scripts and policy for redmine_git_hosting plugin."
        task :remove_scripts_and_policy => [:environment,:remove_policy,:remove_scripts] do
	end
	 
        desc "Generate and install redmine_git_hosting shell scripts."
        task :install_scripts => [:environment] do
            puts "[Generating and installing redmine_git_hosting shell scripts:"

            plugin_roots = redmine_roots("vendor/plugins/redmine_git_hosting")
            plugin_roots.each do |path|
		if path != "#{Rails.root}/vendor/plugins/redmine_git_hosting"
		    # Have to call another rails environment.  Keep default root in that environment
		    chdir File.expand_path("#{path}/../../..") do
		        print %x[rake selinux:redmine_git_hosting:install_scripts_helper]
		    end
		else
		    Rake::Task["selinux:redmine_git_hosting:install_scripts_helper"].invoke
		end
            end
            puts "DONE.]"
	end

        desc "Helper function for generating and installing redmine_git_hosting shell scripts."
        task :install_scripts_helper => [:environment] do 
            web_program = ENV['HTTPD'] || 'httpd'
            web_user = ENV['WEB_USER'] || %x[ps aux | grep #{web_program} | sed "s/ .*$//" | sort -u | grep -v `whoami`].split("\n")[0]
            GitHosting.web_user = web_user

	    # Helper only executed in local environment	
	    path = "#{Rails.root}/vendor/plugins/redmine_git_hosting"
	    print "Clearing out #{path}/bin directory..."
	    %x[rm -rf "#{path}/bin"]
	    puts "Success!"
	    print "Writing customized scripts to #{path}/bin directory..."
	    GitHosting.update_git_exec
	    puts "Success!"
        end

	desc "Remove redmine_git_hosting shell scripts."
	task :remove_scripts => [:environment] do
            puts "[Deleting redmine_git_hosting shell scripts:"
            plugin_roots = redmine_roots("vendor/plugins/redmine_git_hosting")
            plugin_roots.each do |path|
        	sh "rm -rf #{path}/bin"
        	puts "Success!"
            end
            puts "DONE.]"
	end

 	desc "Install selinux tags and policy for redmine_git_hosting."
	task :install_policy => [:environment] do
	    puts "[Installing selinux tags and policy for redmine_git_hosting:"
	    sh "semodule -i #{Rails.root}/vendor/plugins/redmine_git_hosting/selinux/redmine_git.pp"
            puts "DONE.]"
	end

 	desc "Build and install selinux tags and policy for redmine_git_hosting."
	task :build_policy => [:environment] do
	    puts "[Building and installing selinux policy for redmine_git_hosting:"
	    sh "#{Rails.root}/vendor/plugins/redmine_git_hosting/selinux/redmine_git.sh"
            puts "DONE.]"
	end

	desc "Remove selinux tags and policy for redmine_git_hosting."
	task :remove_policy => [:environment] do
	    puts "[Deleting selinux tags and policy for redmine_git_hosting."
	    sh "semodule -r redmine_git | true"
            puts "DONE.]"
	end

	desc "Install file contexts for redmine_git_hosting plugin."
	task :install_contexts => [:environment] do
            plugin_roots = redmine_roots("vendor/plugins/redmine_git_hosting")
            plugin_root_pattern = redmine_root_pattern("vendor/plugins/redmine_git_hosting")
	    puts "[Installing file context for redmine_git_hosting plugin:"
            sh "semanage fcontext -a -t httpd_redmine_git_script_exec_t \"#{plugin_root_pattern}/bin(/.*)?\" | true"

            plugin_roots.each do |path|
                puts "Setting new context for plugin instance at #{path}."
                sh "restorecon -R -p #{path}"
            end
            puts "DONE.]"
	end

	desc "Remove file contexts for redmine_git_hosting plugin."
	task :remove_contexts => [:environment] do
            plugin_roots = redmine_roots("vendor/plugins/redmine_git_hosting")
            plugin_root_pattern = redmine_root_pattern("vendor/plugins/redmine_git_hosting")
	    puts "[Deleting file context for redmine_git_hosting plugin (ignoring errors)."
	    sh "semanage fcontext -d \"#{plugin_root_pattern}/bin(/.*)?\" | true"
            plugin_roots.each do |path|
                puts "Setting new context for plugin instance at #{path}."
                sh "restorecon -R -p #{path}"
            end
            puts "DONE.]"
	end	    
    end
end

#############################################################################
#                                                                           #
# Path support logic                                                        #
#                                                                           #
#############################################################################
@@redmine_roots = {}
@@redmine_root_pattern = ENV['ROOT_PATTERN'] || Rails.root
@@find_maxdepth = 6

# Turn a regex file descriptor (file context) into a 
# conservative (enclosing) globbed expression
#
# Grabbed this from /usr/sbin/fixfiles...
def regex_to_glob(in_regex)
    # clobber anything after space char
    my_regex = in_regex.gsub(/\s.*/,"")
    my_regex = my_regex.gsub(%r|\(([/\w]+)\)\?|,"{\1,}")
    my_regex = my_regex.gsub(%r|([/\w])\?|,"{\1,}")
    my_regex = my_regex.gsub(%r|\?.*|,"*")
    my_regex = my_regex.gsub(%r|\(.*|,"*")
    my_regex = my_regex.gsub(%r|\[.*|,"*")
    my_regex = my_regex.gsub(%r|\.\*.*|,"*")
    my_regex = my_regex.gsub(%r|\.\+.*|,"*")
  
    return my_regex
end

# Return a pattern for the root a redmine installation (as defined
# either by Rails.root or ROOT_PATTERN.
#
# Optional arguments are joined together with "/" as a path and
# appended to the end of the root pattern as described above
def redmine_root_pattern(*optionpath)
    if optionpath.length > 0
        pathend = optionpath.join("/")
        "#{@@redmine_root_pattern}/#{pathend}"
    else
        "#{@@redmine_root_pattern}"
    end
end

# Return an array of pointers to redmine directories as defined by
# the redmine_root_pattern (see above).
#
# When optional arguments are included, they are joined together with
# "/" and appended to the end of each redmine root path.
#
# Note that we use the @@redmine_roots hash to cache our results and
# thus avoid repeating work.
def redmine_roots(*optionpath)
    if @@redmine_roots["/"].nil?
        glob_pattern = regex_to_glob(redmine_root_pattern)
        search_command = "find #{glob_pattern} -maxdepth #{@@find_maxdepth} -type d -regextype posix-extended -regex #{@@redmine_root_pattern} -prune"
        if glob_pattern =~ /.*[\(\[\*\+\?].*/
            puts "Searching for directories matching \"#{@@redmine_root_pattern}\" (may take a bit):"
            puts "#{search_command}"
        end
        new_roots=%x[#{search_command}].split("\n")
        if new_roots.length == 0
            fail "Error: ROOT_PATTERN does not match any directories!"
        end
        @@redmine_roots["/"] = new_roots
    end
    if optionpath.length > 0
        pathend = optionpath.join("/")
        if @@redmine_roots[pathend].nil?
            subpaths = @@redmine_roots["/"].map{|myroot|"#{myroot}/#{pathend}"}.select{|dir|File.directory?(dir)}
            if subpaths.length == 0
                fail "Error: ROOT_PATTERN/#{pathend} does not match any directories!"
            end
            @@redmine_roots[pathend] = subpaths
        end
        @@redmine_roots[pathend]
    else
        @@redmine_roots["/"]
    end
end
