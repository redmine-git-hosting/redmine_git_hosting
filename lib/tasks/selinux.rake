################################################################################
# Rakefile for SELinux installation for Redmine+Redmine Git Hosting Plugin     #
#                                                                              #
# This rakefile provides a variety of options for configuring the SELinux      #
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
#    install new SELinux policy, and install complete SELinux context for      #
#    redmine+redmine_git_hosting plugin                                        #
#                                                                              #
# rake selinux:install RAILS_ENV=xxx ROOT_PATTERN="yyy"                        #
# rake selinux:remove  RAILS_ENV=xxx ROOT_PATTERN="yyy"                        #
#                                                                              #
# 2) Build bin directory with customized scripts for redmine_git_hosting,      #
#    install new SELinux policy, and install SELinux context for               #
#    redmine_git_hosting plugin (not for complete redmine installation).       #
#    This option assumes that the redmine installation (and plugin) code are   #
#    already labeled as "public_content_rw_t" except for dispatch.* files      #
#    which should be labeled as "httpd_sys_script_exec_t".                     #
#                                                                              #
# rake selinux:redmine_git_hosting:install RAILS_ENV=xxx ROOT_PATTERN="yyy"    #
# rake selinux:redmine_git_hosting:remove  RAILS_ENV=xxx ROOT_PATTERN="yyy"    #
#                                                                              #
# 3) Build bin directory with customized scripts for redmine_git_hosting and   #
#    install new SELinux policy. Do not install file contexts of any sort.     #
#    Proper labeling (done in some other way) should have all of redmine       #
#    (including plugins) labeled as "public_content_rw_t", with the exception  #
#    of public/dispatch.* (which should be labeled "httpd_sys_script_exec_t")  #
#    and vendor/plugins/redmine_git_hosting/bin(/.*) which should be labeled   #
#    with the new label "httpd_redmine_git_script_exec_t".                     #
#                                                                              #
# rake selinux:redmine_git_hosting:install_scripts_and_policy RAILS_ENV=xxx ROOT_PATTERN="yyy"
# rake selinux:redmine_git_hosting:remove_scripts_and_policy  RAILS_ENV=xxx ROOT_PATTERN="yyy"
#                                                                              #
################################################################################

@@across_roots_values = []

namespace :selinux do

  desc "Configure SELinux for Redmine and Redmine Git Hosting plugin."
  task :install => [:install_contexts, "selinux:redmine_git_hosting:install"] do
  end

  desc "Unconfigure SELinux for Redmine and Redmine Git Hosting plugin."
  task :remove => ["selinux:redmine_git_hosting:remove", :remove_contexts] do
  end

  desc "Install SELinux file contexts for Redmine (without plugins)."
  task :install_contexts do
    puts "Installing file contexts for Redmine :"
    roots = redmine_roots
    root_pattern = redmine_root_pattern

    sh "semanage fcontext -a -t public_content_rw_t \"#{root_pattern}(/.*)?\""
    sh "semanage fcontext -a -t httpd_sys_script_exec_t \"#{root_pattern}/public/dispatch.*\""

    roots.each do |path|
      puts "Setting new context for Redmine root instance at : '#{path}'."
      sh "restorecon -R -p #{path}"
    end
    puts "Done !"
  end

  desc "Remove SELinux file contexts for Redmine (without plugins)."
  task :remove_contexts do
    puts "Removing file contexts for Redmine (ignoring errors) :"
    roots = redmine_roots
    root_pattern = redmine_root_pattern

    sh "semanage fcontext -d \"#{root_pattern}(/.*)?\""
    sh "semanage fcontext -d \"#{root_pattern}/public/dispatch.*\""

    roots.each do |path|
      puts "Setting new context for Redmine root instance at '#{path}'."
      sh "restorecon -R -p #{path}"
    end
    puts "Done !"
  end


  namespace :redmine_git_hosting do

    desc "Install scripts, policy, and file context for Redmine Git Hosting plugin."
    task :install => [:install_scripts, :install_policy, :install_contexts] do
    end

    desc "Remove scripts, policy, and file context for Redmine Git Hosting plugin."
    task :remove => [:remove_contexts, :remove_policy, :remove_scripts] do
    end

    desc "Install scripts and policy for Redmine Git Hosting plugin."
    task :install_scripts_and_policy => [:install_scripts, :install_policy] do
    end

    desc "Remove scripts and policy for Redmine Git Hosting plugin."
    task :remove_scripts_and_policy => [:remove_policy, :remove_scripts] do
    end

    desc "Call task in all Redmine instances (argument is desired helper task)"
    task :across_roots, [:funname, :pattern] do |t, args|
      @@across_roots_values = []
      redmine_roots.each do |path|
        if getwd == path
          result = %x[rake selinux:redmine_git_hosting:#{args[:funname].to_s}]
          puts result
        else
          chdir path do
            result = %x[rake selinux:redmine_git_hosting:#{args[:funname].to_s}]
            puts result
          end
        end
        if args[:pattern] && retval = /#{args[:pattern]}/.match(result)
          @@across_roots_values << retval[1]
        end
      end
    end

    desc "Generate and install Redmine Git Hosting shell scripts."
    task :install_scripts do
      puts "Generating and installing Redmine Git Hosting shell scripts :"
      Rake::Task["selinux:redmine_git_hosting:across_roots"].reenable
      Rake::Task["selinux:redmine_git_hosting:across_roots"].invoke(:install_scripts_helper, "Populating script dir : (.*)\n")
      puts "Done !"
    end

    desc "Helper function for generating and installing Redmine Git Hosting shell scripts."
    task :install_scripts_helper => [:environment] do

      RedmineGitolite::GitHosting.logger.warn { "Installing scripts from command line (via rake at #{my_date})" }

      web_program = ENV['HTTPD'] || 'httpd'
      web_user = ENV['WEB_USER'] || %x[ps aux | grep #{web_program} | sed "s/ .*$//" | sort -u | grep -v `whoami`].split("\n")[0]

      RedmineGitolite::Config.redmine_user = web_user

      # Helper only executed in local environment
      bin_path = RedmineGitolite::Config.get_scripts_dir_path
      puts "Populating script dir : '#{bin_path}'"
      print "Clearing out script directory... "
      %x[rm -rf "#{bin_path}"]
      puts "Success !"
      print "Writing customized scripts to script directory... "
      RedmineGitolite::Config.update_scripts
      puts "Success !"

      if (ENV['READ_ONLY']||"true").downcase != "false"
        print "Making scripts READ_ONLY... "
        %x[chmod 550 -R "#{bin_path}"]
        puts "Success !"
      else
        print "Making scripts Re-WRITEABLE... "
        %x[chmod 750 -R "#{bin_path}"]
        puts "Success !"
      end
    end

    desc "Remove Redmine Git Hosting shell scripts."
    task :remove_scripts do
      plugin_dir = 'plugins'

      puts "Deleting Redmine Git Hosting shell scripts :"
      if @@across_roots_values.empty?
        puts "Finding script directories :"
        Rake::Task["selinux:redmine_git_hosting:across_roots"].reenable
        Rake::Task["selinux:redmine_git_hosting:across_roots"].invoke(:get_script_directory, "Script directory : (.*)\n")
        puts "Done !"
      end
      @@across_roots_values.each do |bin_path|
        print "Clearing out #{bin_path} directory..."
        %x[rm -rf "#{bin_path}"]
        puts "Success !"
      end
      puts "Done !"
    end


    desc "Helper function for removing Redmine Git Hosting shell scripts."
    task :remove_scripts_helper => [:environment] do
      # Helper only executed in local environment
      bin_path = RedmineGitolite::Config.get_scripts_dir_path
      print "Clearing out '#{bin_path}' directory..."
      %x[rm -rf "#{bin_path}"]
      puts "Success !"
    end


    desc "Install SELinux tags and policy for Redmine Git Hosting."
    task :install_policy => [:environment] do
      puts "Installing SELinux tags and policy for Redmine Git Hosting :"
      sh "semodule -i #{Rails.root}/#{plugin_dir}/redmine_git_hosting/selinux/redmine_git.pp"
      puts "Done !"
    end


    desc "Build and install SELinux tags and policy for Redmine Git Hosting."
    task :build_policy => [:environment] do
      puts "Building and installing SELinux policy for Redmine Git Hosting :"
      sh "#{Rails.root}/#{plugin_dir}/redmine_git_hosting/selinux/redmine_git.sh"
      puts "Done !"
    end


    desc "Remove SELinux tags and policy for Redmine Git Hosting plugin."
    task :remove_policy => [:environment] do
      puts "Deleting SELinux tags and policy for Redmine Git Hosting plugin :"
      sh "semodule -r redmine_git | true"
      puts "Done !"
    end


    desc "Install file contexts for Redmine Git Hosting plugin."
    task :install_contexts do
      puts "Installing file context for Redmine Git Hosting plugin :"
      if @@across_roots_values.empty?
        puts "Finding script directories :"
        Rake::Task["selinux:redmine_git_hosting:across_roots"].reenable
        Rake::Task["selinux:redmine_git_hosting:across_roots"].invoke(:get_script_directory, "Script directory : (.*)\n")
        puts "Done !"
      end

      bin_list = @@across_roots_values.map {|x| x[-1,1]=="/"?x[0..-2]:x}  # Kill off last "/"
      pattern = get_bin_pattern(bin_list)

      sh "semanage fcontext -a -t httpd_redmine_git_script_exec_t \"#{pattern}(/.*)?\" | true" if pattern.class == String
      bin_list.each do |next_dir|
        sh "semanage fcontext -a -t httpd_redmine_git_script_exec_t \"#{next_dir}(/.*)?\" | true" if pattern.class != String
        sh "restorecon -R -p \"#{next_dir}\""
      end
      puts "Done !"
    end

    desc "Remove file contexts for Redmine Git Hosting plugin."
    task :remove_contexts do
      puts "Removing file context for Redmine Git Hosting plugin :"
      if @@across_roots_values.empty?
        puts "Finding script directories :"
        Rake::Task["selinux:redmine_git_hosting:across_roots"].reenable
        Rake::Task["selinux:redmine_git_hosting:across_roots"].invoke(:get_script_directory, "Script directory : (.*)\n")
        puts "Done !"
      end

      bin_list = @@across_roots_values.map {|x| x[-1,1]=="/"?x[0..-2]:x}  # Kill off last "/"
      pattern = get_bin_pattern(bin_list)

      sh "semanage fcontext -d \"#{pattern}(/.*)?\" | true" if pattern.class == String
      bin_list.each do |next_dir|
        sh "semanage fcontext -d \"#{next_dir}(/.*)?\" | true" if pattern.class != String
        sh "restorecon -R -p \"#{next_dir}\""
      end
      puts "Done !"
    end

    desc "Helper function to retrieve binary directory for Redmine Git Hosting plugin"
    task :get_script_directory => [:environment] do
      puts "Script directory : #{RedmineGitolite::Config.get_scripts_dir_path}"
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
      puts "Searching for directories matching '#{@@redmine_root_pattern}' (may take a bit) :"
      puts "#{search_command}"
    end
    new_roots = %x[#{search_command}].split("\n")
    if new_roots.length == 0
      fail "Error: ROOT_PATTERN does not match any directories!"
    end
    @@redmine_roots["/"] = new_roots
  end

  if optionpath.length > 0
    pathend = optionpath.join("/")
    if @@redmine_roots[pathend].nil?
      subpaths = @@redmine_roots["/"].map{|myroot| "#{myroot}/#{pathend}"}.select{|dir| File.directory?(dir)}
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

# Take input list of directories and see if all of them match the root pattern.
# If they do, then return a single pattern, otherwise, return the list...
#
def get_bin_pattern(bin_list)
  # Check to see if root pattern matches... Must match them all -- so
  # Use first pattern as prototype.
  return [] if bin_list.nil?
  if pattern = (/#{@@redmine_root_pattern}\/(.*)/.match(bin_list.first))
    trailer = pattern[1]
    bin_list.drop(1).each do |next_pattern|
      if !(/#{@@redmine_root_pattern}\/#{trailer}/.match(next_pattern))
        return bin_list
      end
    end
    return "#{@@redmine_root_pattern}\/#{trailer}"
  else
    return bin_list
  end
end

# Produce date string of form used by redmine logs
def my_date
  Time.now.strftime("%Y-%m-%d %H:%M:%S")
end
