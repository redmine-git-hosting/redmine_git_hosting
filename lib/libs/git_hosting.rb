require 'lockfile'
require 'net/ssh'
require 'open3'
require 'tmpdir'
require 'tempfile'
require 'stringio'

module GitHosting

  @@logger = nil
  def self.logger
    @@logger ||= MyLogger.new
  end


  ###############################
  ##                           ##
  ##     VARIOUS ACCESSORS     ##
  ##                           ##
  ###############################


  def self.check_hooks_installed
    installed = false
    if lock(5)
      installed = GitAdapterHooks.check_hooks_installed
      unlock()
    end
    installed
  end


  def self.setup_hooks(projects=nil)
    if lock(5)
      GitAdapterHooks.setup_hooks(projects)
      unlock()
    end
  end


  def self.update_global_hook_params
    if lock(5)
      GitAdapterHooks.update_global_hook_params
      unlock()
    end
  end


  def self.git_user_runner
    if !File.exists?(git_user_runner_path())
      update_git_exec
    end
    return git_user_runner_path()
  end


  def self.git_user
    GitHostingConf.git_user
  end


  def self.git_user_runner_path
    return File.join(get_bin_dir, "run_as_git_user")
  end


  def self.git_exec_path
    return File.join(get_bin_dir, "run_git_as_git_user")
  end


  def self.gitolite_ssh_path
    return File.join(get_bin_dir, "gitolite_admin_ssh")
  end


  def self.gitolite_ssh
    if !File.exists?(gitolite_ssh_path())
      update_git_exec
    end
    return gitolite_ssh_path()
  end


  def self.git_exec
    if !File.exists?(git_exec_path())
      update_git_exec
    end
    return git_exec_path()
  end


  def self.redmine_name(repository)
    return File.expand_path(File.join("./",get_full_parent_path(repository, false),repository.git_label),"/")[1..-1]
  end


  def self.repository_name(repository,flags=nil)
    return File.expand_path(File.join("./",GitHostingConf.repository_redmine_subdir,get_full_parent_path(repository, false),repository.git_label(flags)),"/")[1..-1]
  end


  def self.repository_path(repositoryID)
    repo_name = repositoryID.is_a?(String) ? repositoryID : repository_name(repositoryID)
    return File.join(GitHostingConf.repository_base, repo_name) + ".git"
  end


  # Check to see if the given repository exists or not in DB...
  def self.git_repository_exists_in_db?(repo_name)
    if !Repository.find_by_path(repository_path(repo_name)).nil?
      return true
    else
      return false
    end
  end


  # Check to see if the given repository exists or not...
  # Need to work a bit, since we have to su to figure it out...
  def self.git_repository_exists?(repo_name)
    file_exists?(repository_path(repo_name))
  end


  # Are we in the multiple-repositories-per-project version of Redmine?
  @@multi_repos = nil
  def self.multi_repos?
    # Simple -- if Project.repositories exists, it will be an array. Otherwise
    # will throw an exception.
    @@multi_repos ||= Project.new.repositories.is_a?(Array) rescue false
  end


  # Are we in RAILS 3 mode?
  @@rails_3 = nil
  def self.rails_3?
    # Grab major mode from version string....
    @@rails_3 ||= (Rails::VERSION::STRING.split('.')[0].to_i > 2)
  end


  # Configuration file (relative to git conf directory)
  def self.gitolite_conf
    GitoliteConfig.gitolite_conf
  end


  # This is the file portion of the url used when talking through ssh to the repository.
  def self.git_access_url repository
    return "#{repository_name(repository)}"
  end


  # This is the relative portion of the url (below the rails_root) used when talking through httpd to the repository
  # Note that this differs from the git_access_url in not including 'repository_redmine_subdir' as part of the path.
  def self.http_access_url repository
    return "#{GitHostingConf.http_server_subdir}#{redmine_name(repository)}"
  end


  # Server path (minus protocol)
  def self.my_root_url
    # Remove any path from httpServer in case they are leftover from previous installations.
    # No trailing /.
    my_root_path = Redmine::Utils::relative_url_root
    File.join(GitHostingConf.http_server[/^[^\/]*/],my_root_path,"/")[0..-2]
  end


  def self.get_full_parent_path(repository, is_file_path)
    project = repository.project
    return "" if !project.parent || !GitHostingConf.repository_hierarchy
    parent_parts = [];
    p = project
    while p.parent
      parent_id = p.parent.identifier.to_s
      parent_parts.unshift(parent_id)
      p = p.parent
    end
    return is_file_path ? File.join(parent_parts) : parent_parts.join("/")
  end


  ###############################
  ##                           ##
  ##      LOCK FUNCTIONS       ##
  ##                           ##
  ###############################


  @@lock_file = nil
  def self.lock(retries)
    is_locked = false
    if @@lock_file.nil?
      @@lock_file = File.new(File.join(get_tmp_dir, 'redmine_git_hosting_lock'), File::CREAT|File::RDONLY)
    end

    while retries > 0
      is_locked = @@lock_file.flock(File::LOCK_EX|File::LOCK_NB)
      retries -= 1
      if (!is_locked) && retries > 0
        sleep 1
      end
    end
    return is_locked
  end


  def self.unlock
    if !@@lock_file.nil?
      @@lock_file.flock(File::LOCK_UN)
    end
  end


  ###############################
  ##                           ##
  ##      SHELL FUNCTIONS      ##
  ##                           ##
  ###############################


  # Check to see if the given file exists off the git user's homedirectory.
  # Need to work a bit, since we have to su to figure it out...
  def self.file_exists?(filename)
    (%x[#{GitHosting.git_user_runner} test -r '#{filename}' && echo 'yes' || echo 'no']).match(/yes/) ? true : false
  end


  def self.gitolite_version
    stdin, stdout, stderr = Open3.popen3("#{GitHosting.gitolite_ssh} #{GitHosting.git_user}@localhost info")

    if !stderr.readlines.blank?
      return -1
    else
      version = stdout.readlines
      version.each do |line|
        if line =~ /gitolite v?2\./
          return 2
        elsif line.include?('running gitolite3')
          return 3
        else
          return 0
        end
      end
    end
  end


  def self.gitolite_version_output
    stdin, stdout, stderr = Open3.popen3("#{GitHosting.gitolite_ssh} #{GitHosting.git_user}@localhost info")

    errors = stderr.readlines
    if !errors.blank?
      return errors.join("")
    else
      return stdout.readlines.join("")
    end
  end


  ## GET CURRENT USER
  @@web_user = nil
  def self.web_user
    if @@web_user.nil?
      @@web_user = (%x[whoami]).chomp.strip
    end
    return @@web_user
  end


  def self.web_user=(setuser)
    @@web_user = setuser
  end


  ## GET OR CREATE BIN DIR
  @@git_hosting_bin_dir = nil
  @@previous_git_script_dir = nil
  def self.get_bin_dir
    script_dir = GitHostingConf.script_dir
    script_parent = GitHostingConf.script_parent
    if @@previous_git_script_dir != script_dir
      @@previous_git_script_dir = script_dir
      @@git_bin_dir_writeable = nil

      # Directory for binaries includes 'SCRIPT_PARENT' at the end.
      # Further, absolute path adds additional 'git_user' component for multi-gitolite installations.
      if script_dir[0,1] == "/"
        @@git_hosting_bin_dir = File.join(script_dir, git_user, script_parent) + "/"
      elsif Rails::VERSION::MAJOR >= 3
        @@git_hosting_bin_dir = Rails.root.join("plugins/redmine_git_hosting", script_dir, script_parent).to_s + "/"
      else
        @@git_hosting_bin_dir = Rails.root.join("vendor/plugins/redmine_git_hosting", script_dir, script_parent).to_s + "/"
      end
    end
    if !File.directory?(@@git_hosting_bin_dir)
      logger.info "[GitHosting] Creating bin directory: #{@@git_hosting_bin_dir}, Owner #{web_user}"
      %x[mkdir -p "#{@@git_hosting_bin_dir}"]
      %x[chmod 750 "#{@@git_hosting_bin_dir}"]
      %x[chown #{web_user} "#{@@git_hosting_bin_dir}"]

      if !File.directory?(@@git_hosting_bin_dir)
        logger.error "[GitHosting] Cannot create bin directory: #{@@git_hosting_bin_dir}"
      end
    end
    return @@git_hosting_bin_dir
  end


  ## TEST DIRECTORY
  @@git_bin_dir_writeable = nil
  def self.bin_dir_writeable?(*option)
    @@git_bin_dir_writeable = nil if option.length > 0 && option[0] == :reset
    if @@git_bin_dir_writeable == nil
      mybindir = get_bin_dir
      mytestfile = "#{mybindir}/writecheck"
      if (!File.directory?(mybindir))
        @@git_bin_dir_writeable = false
      else
        %x[touch "#{mytestfile}"]
        if (!File.exists?("#{mytestfile}"))
          @@git_bin_dir_writeable = false
        else
          %x[rm "#{mytestfile}"]
          @@git_bin_dir_writeable = true
        end
      end
    end
    @@git_bin_dir_writeable
  end


  ## DO SHELL COMMAND
  def self.shell(command)
    begin
      my_command = "#{command} 2>&1"
      result = %x[#{my_command}].chomp
      code = $?.exitstatus
    rescue Exception => e
      result=e.message
      code = -1
    end
    if code != 0
      logger.error "[GitHosting] Command failed (return #{code}): #{command}"
      message = "  "+result.split("\n").join("\n  ")
      logger.error message
      raise GitHostingException, "Shell Error"
    end
  end


  ## HANDLE MIRROR KEYS
  @@mirror_pubkey = nil
  def self.mirror_push_public_key
    if @@mirror_pubkey.nil?

      %x[cat '#{GitHostingConf.gitolite_ssh_private_key}' | #{GitHosting.git_user_runner} 'cat > ~/.ssh/gitolite_admin_id_rsa ' ]
      %x[cat '#{GitHostingConf.gitolite_ssh_public_key}' | #{GitHosting.git_user_runner} 'cat > ~/.ssh/gitolite_admin_id_rsa.pub ' ]
      %x[ #{GitHosting.git_user_runner} 'chmod 600 ~/.ssh/gitolite_admin_id_rsa' ]
      %x[ #{GitHosting.git_user_runner} 'chmod 644 ~/.ssh/gitolite_admin_id_rsa.pub' ]

      pubk = ( %x[cat '#{GitHostingConf.gitolite_ssh_public_key}' ]  ).chomp.strip
      git_user_dir = ( %x[ #{GitHosting.git_user_runner} "cd ~ ; pwd" ] ).chomp.strip
      %x[ #{GitHosting.git_user_runner} 'echo "#{pubk}"  > ~/.ssh/gitolite_admin_id_rsa.pub ' ]
      %x[ echo '#!/bin/sh' | #{GitHosting.git_user_runner} 'cat > ~/.ssh/run_gitolite_admin_ssh']
      %x[ echo 'exec ssh -T -o BatchMode=yes -o StrictHostKeyChecking=no -p #{GitHostingConf.ssh_server_local_port} -i #{git_user_dir}/.ssh/gitolite_admin_id_rsa        "$@"' | #{GitHosting.git_user_runner} "cat >> ~/.ssh/run_gitolite_admin_ssh"  ]
      %x[ #{GitHosting.git_user_runner} 'chmod 644 ~/.ssh/gitolite_admin_id_rsa.pub' ]
      %x[ #{GitHosting.git_user_runner} 'chmod 600 ~/.ssh/gitolite_admin_id_rsa']
      %x[ #{GitHosting.git_user_runner} 'chmod 700 ~/.ssh/run_gitolite_admin_ssh']

      @@mirror_pubkey = pubk.split(/[\t ]+/)[0].to_s + " " + pubk.split(/[\t ]+/)[1].to_s
    end
    @@mirror_pubkey
  end


  ## SUDO TEST1
  @@sudo_git_to_web_user_stamp = nil
  @@sudo_git_to_web_user_cached = nil
  def self.sudo_git_to_web_user
    if not @@sudo_git_to_web_user_cached.nil? and (Time.new - @@sudo_git_to_web_user_stamp <= 0.5)
      return @@sudo_git_to_web_user_cached
    end
    logger.info "[GitHosting] Testing if git user(\"#{git_user}\") can sudo to web user(\"#{web_user}\")"
    if git_user == web_user
      @@sudo_git_to_web_user_cached = true
      @@sudo_git_to_web_user_stamp = Time.new
      return @@sudo_git_to_web_user_cached
    end
    test = %x[#{GitHosting.git_user_runner} sudo -nu #{web_user} echo "yes" ]
    if test.match(/yes/)
      @@sudo_git_to_web_user_cached = true
      @@sudo_git_to_web_user_stamp = Time.new
      return @@sudo_git_to_web_user_cached
    end
    logger.warn "[GitHosting] Error while testing sudo_git_to_web_user: #{test}"
    @@sudo_git_to_web_user_cached = test
    @@sudo_git_to_web_user_stamp = Time.new
    return @@sudo_git_to_web_user_cached
  end


  ## SUDO TEST2
  @@sudo_web_to_git_user_stamp = nil
  @@sudo_web_to_git_user_cached = nil
  def self.sudo_web_to_git_user
    if not @@sudo_web_to_git_user_cached.nil? and (Time.new - @@sudo_web_to_git_user_stamp <= 0.5)
      return @@sudo_web_to_git_user_cached
    end
    logger.info "[GitHosting] Testing if web user(\"#{web_user}\") can sudo to git user(\"#{git_user}\")"
    if git_user == web_user
      @@sudo_web_to_git_user_cached = true
      @@sudo_web_to_git_user_stamp = Time.new
      return @@sudo_web_to_git_user_cached
    end
    test = %x[#{GitHosting.git_user_runner} echo "yes"]
    if test.match(/yes/)
      @@sudo_web_to_git_user_cached = true
      @@sudo_web_to_git_user_stamp = Time.new
      return @@sudo_web_to_git_user_cached
    end
    logger.warn "[GitHosting] Error while testing sudo_web_to_git_user: #{test}"
    @@sudo_web_to_git_user_cached = test
    @@sudo_web_to_git_user_stamp = Time.new
    return @@sudo_web_to_git_user_cached
  end


  ## GET OR CREATE TEMP DIR
  @@git_hosting_tmp_dir = nil
  @@previous_git_tmp_dir = nil
  def self.get_tmp_dir
    tmp_dir = GitHostingConf.temp_data_dir
    if (@@previous_git_tmp_dir != tmp_dir)
      @@previous_git_tmp_dir = tmp_dir
      @@git_hosting_tmp_dir = File.join(tmp_dir, git_user) + "/"
    end
    if !File.directory?(@@git_hosting_tmp_dir)
      %x[mkdir -p "#{@@git_hosting_tmp_dir}"]
      %x[chmod 700 "#{@@git_hosting_tmp_dir}"]
      %x[chown #{web_user} "#{@@git_hosting_tmp_dir}"]
    end
    return @@git_hosting_tmp_dir
  end


  # Set the history limit for caching on the given repo
  # We assume that the time stamps on the reference files indicate when the latest update occurred.
  def self.set_repository_limit_cache(repo)
    # Find time of newest reference file
    result = %x[#{GitHosting.git_user_runner} find '#{repository_path(repo)}/refs' '#{repository_path(repo)}/packed-refs' -type f -printf "%c," 2> /dev/null].split(",").compact.map{|x| Time.parse(x)}.max
    CachedShellRedirector.limit_cache(repo,result)
  end


  ## CREATE EXECUTABLE FILES
  def self.update_git_exec
    logger.info "[GitHosting] Setting up #{get_bin_dir}"

    File.open(gitolite_ssh_path(), "w") do |f|
      f.puts "#!/bin/sh"
      f.puts "exec ssh -T -o BatchMode=yes -o StrictHostKeyChecking=no -p #{GitHostingConf.ssh_server_local_port} -i #{GitHostingConf.gitolite_ssh_private_key} \"$@\""
    end if !File.exists?(gitolite_ssh_path())

    ##############################################################################################################################
    # So... older versions of sudo are completely different than newer versions of sudo
    # Try running sudo -i [user] 'ls -l' on sudo > 1.7.4 and you get an error that command 'ls -l' doesn't exist
    # do it on version < 1.7.3 and it runs just fine.  Different levels of escaping are necessary depending on which
    # version of sudo you are using... which just completely CRAZY, but I don't know how to avoid it
    #
    # Note: I don't know whether the switch is at 1.7.3 or 1.7.4, the switch is between ubuntu 10.10 which uses 1.7.2
    # and ubuntu 11.04 which uses 1.7.4.  I have tested that the latest 1.8.1p2 seems to have identical behavior to 1.7.4
    ##############################################################################################################################
    sudo_version_str=%x[ sudo -V 2>&1 | head -n1 | sed 's/^.* //g' | sed 's/[a-z].*$//g' ]
    split_version = sudo_version_str.split(/\./)
    sudo_version = 100*100*(split_version[0].to_i) + 100*(split_version[1].to_i) + split_version[2].to_i
    sudo_version_switch = (100*100*1) + (100 * 7) + 3

    File.open(git_exec_path(), "w") do |f|
      f.puts '#!/bin/sh'
      f.puts "if [ \"\$(whoami)\" = \"#{git_user}\" ] ; then"
      f.puts '  cmd=$(printf "\\"%s\\" " "$@")'
      f.puts '  cd ~'
      f.puts '  eval "git $cmd"'
      f.puts "else"
      if sudo_version < sudo_version_switch
        f.puts '  cmd=$(printf "\\\\\\"%s\\\\\\" " "$@")'
        f.puts "  sudo -u #{git_user} -i eval \"git $cmd\""
      else
        f.puts '  cmd=$(printf "\\"%s\\" " "$@")'
        f.puts "  sudo -u #{git_user} -i eval \"git $cmd\""
      end
      f.puts 'fi'
    end if !File.exists?(git_exec_path())

    # use perl script for git_user_runner so we can
    # escape output more easily
    File.open(git_user_runner_path(), "w") do |f|
      f.puts '#!/usr/bin/perl'
      f.puts ''
      f.puts 'my $command = join(" ", @ARGV);'
      f.puts ''
      f.puts 'my $user = `whoami`;'
      f.puts 'chomp $user;'
      f.puts 'if ($user eq "' + git_user + '")'
      f.puts '{'
      f.puts '  exec("cd ~ ; $command");'
      f.puts '}'
      f.puts 'else'
      f.puts '{'
      f.puts '  $command =~ s/\\\\/\\\\\\\\/g;'
      # Previous line turns \; => \\;
      # If old sudo, turn \\; => "\\;" to protect ';' from loss as command separator during eval
      if sudo_version < sudo_version_switch
        f.puts '  $command =~ s/(\\\\\\\\;)/"$1"/g;'
        f.puts "  $command =~ s/'/\\\\\\\\'/g;"
      end
      f.puts '  $command =~ s/"/\\\\"/g;'
      f.puts '  exec("sudo -u ' + git_user + ' -i eval \"$command\"");'
      f.puts '}'
    end if !File.exists?(git_user_runner_path())

    File.chmod(0550, git_exec_path())
    File.chmod(0550, gitolite_ssh_path())
    File.chmod(0550, git_user_runner_path())
    %x[chown #{web_user} -R "#{get_bin_dir}"]
  end


  # Try to get a cloned version of gitolite-admin repository.
  #
  # This code tries to recover from a variety of errors which have been observed
  # in the field, including a loss of the admin key and an empty top-level directory
  #
  # Return: false => have uncommitted changes
  #   true =>  directory on master
  #
  # This routine must only be called after acquisition of the lock
  #
  # John Kubiatowicz, 11/15/11
  #
  # This routine will no-longer merge in changes, since this can cause weird behavior
  # when interacting with cron-jobs that clean up /tmp.
  #
  # John Kubiatowicz, 04/23/12
  #
  def self.clone_or_pull_gitolite_admin(resync_all_flag)
    # clone/pull from admin repo
    repo_dir = File.join(get_tmp_dir, GitHosting::GitoliteConfig::ADMIN_REPO)

    # If preexisting directory exists, try to clone and merge....
    if (File.exists? "#{repo_dir}") && (File.exists? "#{repo_dir}/.git") && (File.exists? "#{repo_dir}/keydir") && (File.exists? "#{repo_dir}/conf")
      begin
        logger.info "[GitHosting] Fetching changes from Gitolite Admin repository to '#{repo_dir}'"
        shell %[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' fetch]
        shell %[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' merge FETCH_HEAD]

        # unmerged changes=> non-empty return
        return_val = %x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' status --short].empty?

        if (return_val)
          shell %[chmod 700 "#{repo_dir}"]
          # Make sure we have our hooks setup
          GitAdapterHooks.check_hooks_installed
          return return_val
        else
          # The attempt to merge can cause a weird failure mode when interacting with cron jobs that clean out old
          # files in /tmp.  The issue is that keys in the keydir can go idle and get deleted.  Then, when we merge we
          # create an admin repo minus those keys (including the admin key!).  Only a RESYNC_ALL operation will
          # actually fix.      Thus, we never return "have uncommitted changes", but instead fail the merge and reclone.
          #
          # 04/23/12
          # --KUBI--
          logger.error "[GitHosting] Seems to be unmerged changes! Going to delete and reclone for safety."
          logger.error "[GitHosting] May need to execute RESYNC_ALL to fix whatever caused pending changes." unless resync_all_flag
        end
      rescue
        logger.error "Repository fetch and merge failed -- trying to delete and reclone Gitolite Admin repository."
      end
    end

    begin
      logger.info "[GitHosting] Cloning Gitolite Admin repository to '#{repo_dir}'"
      shell %[rm -rf "#{repo_dir}"]
      shell %[env GIT_SSH=#{gitolite_ssh()} git clone ssh://#{git_user}@localhost/gitolite-admin.git #{repo_dir}]
      shell %[chmod 700 "#{repo_dir}"]

      # Make sure we have our hooks setup
      GitAdapterHooks.check_hooks_installed

      return true # On master (fresh clone)
    rescue => e
      logger.error e.message
      logger.error "Cannot clone Gitolite Admin repository. Try to fix it!"

      begin
        # Try to repair admin access.
        fixup_gitolite_admin

        logger.info "[GitHosting] Recloning Gitolite Admin repository to '#{repo_dir}'"
        shell %[rm -rf "#{repo_dir}"]
        shell %[env GIT_SSH=#{gitolite_ssh()} git clone ssh://#{git_user}@localhost/gitolite-admin.git #{repo_dir}]
        shell %[chmod 700 "#{repo_dir}"]

        # Make sure we have our hooks setup
        GitAdapterHooks.check_hooks_installed

        return true # On master (fresh clone)
      rescue => e
        logger.error e.message
        logger.error "Cannot clone Gitolite Admin repository. Requires human intervention !!!"
      end
    end
  end


  # Recover from failure to clone repository.
  #
  # This routine attempts to recover from a failure to clone by reestablishing the gitolite
  # key.  It does so by directly cloning the gitolite-admin repository and editing the configuration
  # file (gitolite.conf).      If we ever try to allow gitolite services on a separate server from Redmine,
  # we will have to turn this into a stand-alone script.
  #
  # Ideally, we have gitolite >= 2.0.3 so that we have 'gl-admin-push'.  If not, we try to use gl-setup
  # which has some quirks and is not as good.
  #
  # We try to:
  #  (1) figure out what the proper name is for the access key by first looking for a matching keyname
  #      in the keydir, then in the conf file.
  #  (2) delete any keys in the keydir that match our key
  #  (3) reestablish the keyname in the conf file and the key in the keydir
  #  (4) push the result back to the admin repo.
  #
  # We attempt avoid messing with other administrative keys in the conf file (unless they are unmatched
  # by keys in the keydir directory (in which case we remove them).
  #
  # Most of this activity is all done as the git user, hence the long command lines.  Only parsing of the
  # conf file is done as the redmine user (hence the need for the separate "tmp_conf_dir".
  #
  # Return: on success, returns "Success!".  On Failure, throws a GitHostingException.
  #
  # Consider this the "nuclear" option....
  def self.fixup_gitolite_admin
    unless GitoliteConfig.has_admin_key?
      raise GitHostingException, "Cannot repair Gitolite Admin key : Admin key is not managed by Redmine!"
    end

    logger.warn "[GitHosting] Attempting to restore Gitolite Admin key :"

    begin
      if GitHosting.gitolite_version == 2
        gitolite_command = 'gl-admin-push -f'
      elsif GitHosting.gitolite_version == 3
        gitolite_command = 'gitolite push -f'
      else
        raise GitHostingException, "Unknown Gitolite Version"
      end

      repo_dir  = File.join(Dir.tmpdir, "fixrepo", git_user, GitHosting::GitoliteConfig::ADMIN_REPO)
      conf_file = File.join(repo_dir, "conf", gitolite_conf)
      keydir    = File.join(repo_dir, 'keydir')

      tmp_conf_dir  = File.join(Dir.tmpdir, "fixconf", git_user)
      tmp_conf_file = File.join(tmp_conf_dir, gitolite_conf)

      admin_repo = "#{GitHostingConf.repository_base}/#{GitHosting::GitoliteConfig::ADMIN_REPO}"

      logger.warn "[GitHosting] Cloning Gitolite Admin repository '#{admin_repo}' directly as '#{git_user}' in '#{repo_dir}'"

      shell %[rm -rf "#{repo_dir}"] if File.exists?(repo_dir)
      shell %[#{GitHosting.git_user_runner} git clone #{admin_repo} #{repo_dir}]

      # Load up existing conf file
      shell %[mkdir -p #{tmp_conf_dir}]
      shell %[mkdir -p #{keydir}]

      shell %[#{GitHosting.git_user_runner} 'cat #{conf_file}' | cat > #{tmp_conf_file}]
      conf = GitoliteConfig.new(tmp_conf_file)

      # copy key into home directory...
      shell %[cat #{GitHostingConf.gitolite_ssh_public_key} | #{GitHosting.git_user_runner} 'cat > ~/id_rsa.pub']

      # Locate any keys that match redmine_git_hosting key
      raw_admin_key_matches = %x[#{GitHosting.git_user_runner} 'find #{keydir} -type f -exec cmp -s ~/id_rsa.pub {} \\; -print'].chomp.split("\n")

      # Reorder them by putting preferred keys first
      preferred = ["#{GitHosting::GitoliteConfig::DEFAULT_ADMIN_KEY_NAME}","id_rsa.pub"]
      raw_admin_key_matches = promote_array(raw_admin_key_matches, preferred)

      # Remove all but first one
      first_match = nil
      raw_admin_key_matches.each do |name|
        # Take basename and remove as many ".pub" as you can
        working_basename = /^(.*\/)?([^\/]*?)(\.pub)*$/.match(name)[2]
        if first_match || ("#{working_basename}.pub" != File.basename(name))
          logger.warn "[GitHosting] Removing duplicate administrative key '#{File.basename(name)}' from keydir"
          shell %[#{GitHosting.git_user_runner} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' rm #{name}]
        end
        # First name will match this
        first_match ||= working_basename
      end

      # Find any admin keys in conf file that don't have a corresponding keyfile
      # At this point, would include any of the keys that we have deleted, above
      extrakeys = conf.get_admin_keys - Dir.entries(keydir).map {|name| File.basename(name,".pub")}

      # Try to deduce administrative key name first from keydir, then from conf file, then use default.
      # Remove any extra ".pub" at end, in case something slipped through
      new_admin_key_name = /^(.*?)(.pub)*$/.match(first_match || extrakeys.first || GitHosting::GitoliteConfig::DEFAULT_ADMIN_KEY_NAME)[1]

      # Remove extraneous keys from
      extrakeys.each do |keyname|
        unless keyname == new_admin_key_name
          logger.warn "[GitHosting] Removing orphan administrative key '#{keyname}' from Gitolite config file"
          conf.delete_admin_keys keyname
        end
      end

      logger.warn "[GitHosting] Establishing '#{new_admin_key_name}.pub' as the Gitolite Admin key"

      # Add selected key to front of admin list
      admin_keys = ([new_admin_key_name] + conf.get_admin_keys).uniq
      if (admin_keys.length > 1)
        logger.warn "[GitHosting] Additional administrative key(s): #{admin_keys[1..-1].map{|x| "'#{x}.pub'"}.join(', ')}"
      end
      conf.set_admin_keys admin_keys
      conf.save

      shell %[cat #{tmp_conf_file} | #{GitHosting.git_user_runner} 'cat > #{conf_file}']
      shell %[#{GitHosting.git_user_runner} 'mv ~/id_rsa.pub #{keydir}/#{new_admin_key_name}.pub']
      shell %[#{GitHosting.git_user_runner} "git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' add keydir/*"]
      shell %[#{GitHosting.git_user_runner} "git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' add conf/#{gitolite_conf}"]
      shell %[#{GitHosting.git_user_runner} "git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' config user.email '#{Setting.mail_from}'"]
      shell %[#{GitHosting.git_user_runner} "git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' config user.name 'Redmine'"]
      shell %[#{GitHosting.git_user_runner} "git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' commit -m 'Updated by Redmine: Emergency repair of Gitolite Admin key'"]

      logger.warn "[GitHosting] Pushing fixes using '#{gitolite_command}'"
      shell %[#{GitHosting.git_user_runner} "cd #{repo_dir}; #{gitolite_command}"]

      %x[#{GitHosting.git_user_runner} 'rm -rf "#{File.join(Dir.tmpdir,'fixrepo')}"']
      %x[rm -rf "#{File.join(Dir.tmpdir,'fixconf')}"]
      logger.warn "[GitHosting] Success!"
      logger.warn ""
    rescue => e
      logger.error "Failed to reestablish Gitolite Admin key."
      logger.error e.message
      logger.error e.backtrace.join("\n")
      %x[#{GitHosting.git_user_runner} 'rm -f ~/id_rsa.pub']
      %x[#{GitHosting.git_user_runner} 'rm -rf "#{File.join(Dir.tmpdir, 'fixrepo')}"']
      %x[rm -rf "#{File.join(Dir.tmpdir, 'fixconf')}"]
      raise GitHostingException, "Failure to repair Gitolite Admin key"
    end
  end


  # Commit Changes to the gitolite-admin repository.  This assumes that repository exists
  # (i.e. that a clone_or_fetch_gitolite_admin has already be called).
  #
  # This routine must only be called after acquisition of the lock
  #
  # John Kubiatowicz, 11/15/11
  def self.commit_gitolite_admin(*args)
    resyncing = args && args.first

    # create tmp dir, return cleanly if, for some reason, we don't have proper permissions
    repo_dir = File.join(get_tmp_dir,GitHosting::GitoliteConfig::ADMIN_REPO)

    logger.info ""
    logger.info "[GitHosting] ############ COMMIT CHANGES ############"

    # commit / push changes to gitolite admin repo
    begin
      if (!resyncing)
        logger.info "[GitHosting] Committing changes to Gitolite Admin repository"
        message = "Updated by Redmine"
      else
        logger.info "[GitHosting] Committing corrections to Gitolite Admin repository"
        message = "Updated by Redmine : Corrections discovered during RESYNC_ALL"
      end
      shell %[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' add keydir/*]
      shell %[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' add conf/#{gitolite_conf}]
      shell %[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' config user.email '#{Setting.mail_from}']
      shell %[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' config user.name 'Redmine']
      shell %[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' commit -a -m '#{message}']
      shell %[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' push -u origin master]
      logger.info ""
    rescue
      logger.error "Problems committing changes to Gitolite Admin repository!! Probably requires human intervention"
      logger.error ""
      raise GitHostingException, "Gitolite Admin repository commit failure"
    end
  end


  # Update keys for all members of projects of interest
  #
  # This code is entirely self-correcting for keys owned by users of the specified
  # projects.  It should work regardless of the history of steps that got us here.
  #
  # Note that this code has changed from the original.  Now, we look at all keys owned
  # by users in the specified projects to make sure that they are still live.  We
  # do this with a single pass through the keydir and do not rely on the "inactive"
  # status to tell us that a key should be deleted.  The reason is that weird
  # synchronization issues (not entirely understood) can cause phantom keys to get left
  # in the keydir which can really mess up gitolite.
  #
  # As of the latest release, we also recover from a variety of aborted MOVE and DELETE
  # operations.  Further, we better handle movement of complete trees of projects.
  #
  # Also, when performing :resync_all, if the 'deleteGitRepositories' setting is 'true',
  # then we will remove repositories in the configuration file (gitolite.conf) that are
  # identifiable as "redmine managed" (because they have one or more keys of the right form)
  # but which are nolonger live for some reason (probably because the project was deleted).
  #
  # John Kubiatowicz, 01/04/12
  #
  # Usage:
  #
  # 1) update_repositories(project) => update for specified project
  # 2) update_repositories([list of projects]) => update all projects
  # 3) update_repositories(:flag1=>true, :flag2 => false)
  #
  # Current flags:
  # :resync_all =>  go through all redmine-maintained gitolite repos,
  #     clean up keydir, delete unused keys, clean up gitolite.conf
  # :delete     =>  Clean up keydir, delete unused keys, remove redmine-maintaind
  #     gitolite entries and repositories unassociated with live projects.
  #     Unlike :resync_all, do not fix up live projects
  # :descendants => for every given project, update self and all decendants
  # :archive    =>  Project is being archived -- remove keys from gitolite.conf,
  #     and possibly keydir if not used by any other project
  #
  @@recursionCheck = false
  def self.update_repositories(*args)
    flags = {}
    args.each {|arg| flags.merge!(arg) if arg.is_a?(Hash)}
    reposym = (multi_repos? ? :repositories : :repository)

    logger.info ""
    logger.info "[GitHosting] ############ GRAB PROJECTS TO WORK ON ############"

    if flags[:resync_all]
      logger.info "[GitHosting] Executing RESYNC_ALL operation on Gitolite configuration"
      projects = Project.active_or_archived.find(:all, :include => reposym)
    elsif flags[:delete]
      # When delete, want to recompute users, so need to go through all projects
      logger.info "[GitHosting] Executing DELETE operation (resync keys, remove dead repositories)"
      projects = args[0]
    elsif flags[:archive]
      # When archive, want to recompute users, so need to go through all projects
      logger.info "[GitHosting] Executing ARCHIVE operation (remove keys)"
      projects = Project.active_or_archived.find(:all, :include => reposym)
    elsif flags[:descendants]
      logger.info "[GitHosting] Executing RESYNC_ALL operation on Gitolite configuration for projects and descendants"
      if Project.method_defined?(:self_and_descendants)
        projects = (args.flatten.select{|p| p.is_a?(Project)}).collect{|p| p.self_and_descendants}.flatten
      else
        projects = Project.active_or_archived.find(:all, :include => reposym)
      end
    else
      logger.info "[GitHosting] No flags set, RESYNC_KEYS for projects"
      projects = args.flatten.select{|p| p.is_a?(Project)}
    end

    # Only take projects that have Git repos.
    if flags[:delete]
      git_projects = projects
    else
      git_projects = projects.uniq.select{|p| p.gl_repos.any?}
    end

    if git_projects.empty?
      logger.info "[GitHosting] Got no projects to work on..."
      logger.info ""
      return
    else
      logger.info "[GitHosting] Got projects, move on!"
      logger.info ""
    end

    if(defined?(@@recursionCheck))
      if(@@recursionCheck)
        # This shouldn't happen any more -- log as error
        logger.error "[GitHosting] update_repositories() exited with positive recursionCheck flag!"
        logger.error ""
        return
      end
    end

    @@recursionCheck = true

    # Grab actual lock
    if !lock(GitHostingConf.lock_wait_time)
      logger.error "[GitHosting] update_repositories() exited without acquiring lock!"
      logger.error ""
      @@recursionCheck = false
      return
    end

    begin
      # Make sure we have gitolite-admin cloned.
      # If have uncommitted changes, reflect in "changed" flag.
      logger.info "[GitHosting] ############ GRAB GITOLITE ADMIN REPO ############"
      changed = !clone_or_pull_gitolite_admin(flags[:resync_all])

      # Get directory for the gitolite-admin
      repo_dir = File.join(get_tmp_dir, "gitolite-admin")

      logger.info ""
      logger.info "[GitHosting] ############ UPDATE SSH KEYS ############"
      logger.info "[GitHosting] Updating key directory for projects : '#{git_projects.join ', '}'"

      keydir = File.join(repo_dir, "keydir")
      old_keyhash = {}

      Dir.foreach(keydir) do |keyfile|
        user_token = GitolitePublicKey.ident_to_user_token(keyfile)
        if !user_token.nil?
          old_keyhash[user_token] ||= []
          old_keyhash[user_token] << keyfile
        end
      end

      # Collect relevant users into hash with user as key and activity (in some active project) as value
      (git_projects.select{|proj| proj.active? && proj.module_enabled?(:repository)}.map{|proj| proj.member_principals.map(&:user).compact}.flatten.uniq << GitolitePublicKey::DEPLOY_PSEUDO_USER).each do |cur_user|

        if cur_user == GitolitePublicKey::DEPLOY_PSEUDO_USER
          active_keys = DeploymentCredential.active.select(&:honored?).map(&:gitolite_public_key).uniq
          cur_token = cur_user

          # Remove inactive Deployment Credentials
          DeploymentCredential.inactive.each {|cred| DeploymentCredential.destroy(cred.id)}
        else
          active_keys = cur_user.gitolite_public_keys.active.user_key || []
          cur_token = GitolitePublicKey.user_to_user_token(cur_user)

          # Remove inactive keys (will be deleted below)
          cur_user.gitolite_public_keys.inactive.each {|key| GitolitePublicKey.destroy(key.id)}
        end

        # Current filenames
        old_keynames = old_keyhash[cur_token] || []
        cur_keynames = []

        # Get list of active keys that SHOULD be in the keydir
        active_keys.each do |key|
          key_id = key.identifier
          key_token = GitolitePublicKey.ident_to_user_token(key_id)

          if key_token != cur_token
            # Rare case -- user login changed.  Fix it.
            key_id = key.reset_identifier

            # Add all key filenames with this (incorrect) token into the set of names
            old_keynames += (old_keyhash[key_token] || [])
            old_keyhash.delete(key_token)
          end
          cur_keynames.push "#{key_id}.pub"
        end

        keys_to_delete = (old_keynames - cur_keynames)
        keys_to_delete.each do |keyname|
          logger.warn "[GitHosting] Removing Redmine key from Gitolite : '#{keyname}'"
          %x[git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' rm keydir/#{keyname}]
          changed = true
        end

        # Add missing keys to the keydir
        active_keys.each do |key|
          keyname = "#{key.identifier}.pub"
          unless old_keynames.index(keyname)
            filename = File.join(keydir, keyname)
            logger.info "[GitHosting] Adding Redmine key to Gitolite : '#{keyname}'"
            File.open(filename, 'w') {|f| f.write(key.key.gsub(/\n/,'')) }
            changed = true
          end
        end

        # In preparation for resync_all, below
        old_keyhash.delete(cur_token)
      end

      # Remove keys for deleted users
      orphanString = flags[:resync_all] ? "orphan " : ""

      if flags[:resync_all] || flags[:archive]
        # All keys left in old_keyhash should be for users nolonger authorized for gitolite repos
        old_keyhash.each_value do |keyset|
          keyset.each do |keyname|
            logger.warn "[GitHosting] Removing #{orphanString}Redmine key from Gitolite : '#{keyname}'"
            %x[git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' rm keydir/#{keyname}]
            changed = true
          end
        end
      end

      conf = GitoliteConfig.new(File.join(repo_dir, 'conf', gitolite_conf))

      # Current redmine repositories (basename=>{repo_name1=>true,repo_name2=>true})
      redmine_repos = conf.redmine_repo_map

      # The set of actual repositories (basename=>{repo_name1=>true,repo_name2=>true})
      actual_repos = GitoliteConfig.gitolite_repository_map

      # Set of all entries in gitolite.conf file (name1=>1, name2=>2)
      total_entries = conf.all_repos

      # Projects for which we want to update hooks
      new_projects = []

      # Flag to force conf file to get new timestamp
      force_change = false

      # Regenerate configuration file for repos of projects of interest
      # Also, try to match up actual repositories with projects (being somewhat conservative
      # when a project might be out of control of redmine.
      #
      # Note that we go through all projects, including archived ones, since we may need to
      # find orphaned repos.  Archived projects get left with a "ARCHIVED_REDMINE_KEY".
      git_projects.each do |proj|

        # First, get project-specific read/write keys
        # fetch users
        proj_read_user_keys =  []
        proj_write_user_keys = []

        proj.member_principals.map(&:user).compact.uniq.each do |user|
          if user.allowed_to?(:commit_access, proj)
            proj_write_user_keys += user.gitolite_public_keys.active.user_key.map(&:identifier)
          elsif user.allowed_to?(:view_changesets, proj)
            proj_read_user_keys += user.gitolite_public_keys.active.user_key.map(&:identifier)
          end
        end

        proj.gl_repos.each do |repo|
          repo_name = repository_name(repo)

          logger.info ""
          logger.info "[GitHosting] ############ UPDATE GITOLITE CONF FOR REPO '#{repo_name}' ############"

          # Common case: these are hashes with zero or one one element (except when
          # Repository.repo_ident_unique? is false)
          my_entries = redmine_repos[repo.git_name]
          my_repos = actual_repos[repo.git_name]

          # We have one or more gitolite.conf entries with the right base name.  Pick one with
          # closest name (will pick one with 'repo_name' if it exists).
          closest_entry = closest_path(my_entries,repo_name,repo)
          if !closest_entry
            # CREATION case.
            if !total_entries[repo_name]
              logger.warn "[GitHosting] Creating new entry '#{repo_name}' in '#{gitolite_conf}'"
            else
              logger.warn "[GitHosting] Using existing entry '#{repo_name}' in '#{gitolite_conf}' for creation"
            end
          elsif closest_entry != repo_name
            # MOVE case.
            logger.warn "[GitHosting] Moving entry '#{closest_entry}' to '#{repo_name}' in '#{gitolite_conf}'."
            conf.rename_repo(closest_entry,repo_name)
          else
            # NORMAL case. Have entry with correct name.
            if !my_repos[repo_name]
              logger.warn "[GitHosting] Missing or misnamed repository for existing Gitolite entry : '#{repo_name}'."
            else
              logger.warn "[GitHosting] Using existing entry '#{repo_name}' in '#{gitolite_conf}'"
            end
          end

          new_projects << proj unless my_repos[closest_entry] # Reinit hooks unless NORMAL or MOVE case
          my_entries.delete closest_entry      # Claimed this one => don't need to delete later

          if my_repos.empty?
            # This is the normal CREATION case for primary repos or when repo_ident_unique? true.
            # No repositories with matching basenames.  Attempt to recover repository from recycle_bin,
            # if present.  Else, create new repository.
            if !GitoliteRecycle.recover_repository_if_present repo_name
              force_change = true
              logger.warn "[GitHosting] Let Gitolite create empty repository : '#{repository_path(repo_name)}'"
            end
          elsif my_repos[closest_entry]
            # We have a repository that matches the entry we used above.  Move this one to match if necessary
            # If closest_entry == repo_name, this is a NORMAL case (do nothing!)
            # If closest_entry != repo_name, this is the MOVE case.
            if closest_entry != repo_name
              move_physical_repo(closest_entry, repo_name)
            else
              logger.warn "[GitHosting] Using existing Gitolite repository : '#{repository_path(repo_name)}' for update (1)"
            end
          elsif my_repos[repo_name]
            # Existing repo with right name.  We know that there wasn't a corresponding gitolite.conf entry....
            logger.warn "[GitHosting] Using existing Gitolite repository : '#{repository_path(repo_name)}' for update (2)"
          else
            # Of the repos in my_repo with a matching base name, only steal away those not already controlled
            # by gitolite.conf.  The one reasonable case here is if (for some reason) a move was properly executed
            # in gitolite.conf but the repo didn't get moved.
            closest_repo = closest_path(hash_set_diff(my_repos,total_entries),repo_name,repo)
            if !closest_repo
              # Attempt to recover repository from recycle_bin, if present.  Else, create new repository.
              if !GitoliteRecycle.recover_repository_if_present repo_name
                force_change = true
                logger.warn "[GitHosting] Let Gitolite create empty repository : '#{repository_path(repo_name)}'"
              end
            else
              logger.warn "[GitHosting] Claiming orphan repository '#{repository_path(closest_repo)}' in Gitolite repositories."
              move_physical_repo(closest_repo,repo_name)
            end
          end

          # Update repository url and root_url if necessary
          target_url = repository_path(repo_name)
          if repo.url != target_url || repo.root_url != target_url
            # logger.warn "  Updating internal access path to '#{target_url}'."
            repo.url = repo.root_url = target_url
            repo.save
          end

          # If this is an active (non-archived) project, then update gitolite entry.  Add GIT_DAEMON_KEY.
          if proj.active?
            if proj.module_enabled?(:repository)
              # Get deployment keys (could be empty)
              read_user_keys  = []
              write_user_keys = []

              repo.deployment_credentials.active.select(&:honored?).each do |cred|
                if cred.allowed_to?(:commit_access)
                  write_user_keys << cred.gitolite_public_key.identifier
                elsif cred.allowed_to?(:view_changesets)
                  read_user_keys << cred.gitolite_public_key.identifier
                end
              end

              # Add project-specific keys
              write_user_keys += proj_write_user_keys
              read_user_keys += proj_read_user_keys

              # Git daemon support
              if (repo.extra.git_daemon == 1 || repo.extra.git_daemon == nil ) && repo.project.is_public
                read_user_keys.push GitoliteConfig::GIT_DAEMON_KEY
              end

              # Remove previous redmine keys, then add new keys
              # By doing things this way, we leave non-redmine keys alone
              # Note -- delete_redmine_keys() will also remove the GIT_DAEMON_KEY for repos with redmine keys
              # (to be put back as above, when appropriate).
              conf.delete_redmine_keys repo_name
              conf.add_read_user repo_name, read_user_keys.uniq
              conf.add_write_user repo_name, write_user_keys.uniq

              # If no redmine keys, mark with dummy key
              if (read_user_keys+write_user_keys).empty?
                conf.mark_with_dummy_key repo_name
              end
            else
              # Must be a project that has repositories disabled. Mark as disabled project.
              conf.delete_redmine_keys repo_name
              conf.mark_disabled repo_name
            end
          else
            # Must be an archive project! Clear out redmine keys. Mark as an archived project.
            conf.delete_redmine_keys repo_name
            conf.mark_archived repo_name
          end
        end
      end

      # If resyncing or deleting, check for orphan repositories which still have redmine keys...
      # At this point, redmine_repos contains all repositories in original gitolite.conf
      # which have redmine keys but are not part of an active redmine project.
      if flags[:resync_all] || flags[:delete]

        redmine_repos.values.map(&:keys).flatten.each do |repo_name|

          # First, check if there are any redmine keys other than the DUMMY or ARCHIVED key
          has_keys = conf.has_actual_redmine_keys? repo_name

          # Next, delete redmine keys for this repository
          conf.delete_redmine_keys repo_name unless git_repository_exists_in_db? repo_name

          if GitHostingConf.delete_git_repositories?
            if conf.repo_has_no_keys? repo_name
              logger.info ""
              logger.info "[GitHosting] ############ DELETE GITOLITE CONF FOR REPO '#{repo_name}' ############"
              logger.warn "[GitHosting] Deleting #{orphanString}Gitolite repository '#{repo_name}' from '#{gitolite_conf}'"
              conf.delete_repo repo_name
              GitoliteRecycle.move_repository_to_recycle repo_name
            end
          end
        end

        # Delete expired files from recycle bin.
        GitoliteRecycle.delete_expired_files
      end

      if conf.changed? || force_change
        conf.save
        changed = true
      end

      if changed
        # Have changes. Commit / push changes to gitolite admin repo
        commit_gitolite_admin flags[:resync_all]
      end

      # Set post receive hooks for new projects (or check all repositories on :resync_all).
      # We need to do this AFTER push, otherwise necessary repos may not be created yet.
      GitAdapterHooks.setup_hooks_params((flags[:resync_all] || flags[:resync_hooks]) ? git_projects : new_projects)

    rescue GitHostingException
      logger.error "update_repositories() failed"
    rescue => e
      logger.error e.message
      logger.error e.backtrace[0..4].join("\n")
      logger.error "update_repositories() failed"
    end

    unlock()
    @@recursionCheck = false
  end


  # This routine moves a repository in the gitolite repository structure.
  def self.move_physical_repo(old_name,new_name)
    begin
      logger.warn "[GitHosting] Moving gitolite repository from '#{old_name}.git' to '#{new_name}.git'"

      if git_repository_exists? new_name
        logger.error "[GitHosting] Repository already exists at #{new_name}.git!  Moving to recycle bin to avoid overwrite."
        GitoliteRecycle.move_repository_to_recycle new_name
      end

      # physicaly move the repo BEFORE committing/pushing conf changes to gitolite admin repo
      prefix = new_name[/.*(?=\/)/] # Complete directory path (if exists) without trailing '/'
      if prefix
        # Has subdirectory.  Must construct destination directory
        repo_prefix = File.join(GitHostingConf.repository_base, prefix)
        GitHosting.shell %[#{git_user_runner} mkdir -p '#{repo_prefix}']
      end
      old_path = repository_path(old_name)
      new_path = repository_path(new_name)
      shell %[#{git_user_runner} 'mv "#{old_path}" "#{new_path}"']

      # If any empty directories left behind, try to delete them.  Ignore failure.
      old_prefix = old_name[/.*?(?=\/)/] # Top-level old directory without trailing '/'
      if old_prefix
        repo_subpath = File.join(GitHostingConf.repository_base, old_prefix)
        result = %x[#{GitHosting.git_user_runner} find '#{repo_subpath}' -depth -type d ! -regex '.*\.git/.*' -empty -delete -print].chomp.split("\n")
        result.each { |dir| logger.warn "[GitHosting] Removing empty repository subdirectory : #{dir}"}
      end
    rescue GitHostingException
      logger.error "move_physical_repo(#{old_name},#{new_name}) failed"
    rescue => e
      logger.error e.message
      logger.error e.backtrace[0..4].join("\n")
      logger.error "move_physical_repo(#{old_name},#{new_name}) failed"
    end
  end


  # Takes a presence hash of path names and a path name and attempts to find the item in the list that matches
  # in the most components.  Assume at least one element in list
  #
  # Dealing with the multi-repo spec makes this slightly more complex that without.  We want
  # to be able to recognize the path in either of the two repository naming schemes:
  #
  # 1) proj1/proj2/parent-proj               : Used when all repo identifiers are unique
  # 2) proj1/proj2/parent-proj/repo_ident    : Used when repo identifiers may not be unique
  #
  # Note that all the complexity of dealing with multi-repo path formats is handled here
  def self.closest_path(path_list,repo_name,repo)
    # most common case: have exact matching path
    return repo_name if path_list[repo_name]

    # Special handling if repository name could change with Repository.repo_ident_unique?
    if GitHosting.multi_repos? && !repo.identifier.blank?
      # See if we find match by merely changing value of Repository.repo_ident_unique?
      repo_name_alt = repository_name(repo,:assume_unique => !Repository.repo_ident_unique?)
      if path_list[repo_name_alt]
        # Make sure that this doesn't belong to another repo
        owner_repo = Repository.find_by_path(repo_name_alt,:loose => true)
        if !owner_repo || owner_repo == repo
          return repo_name_alt
        end
      end
    end

    # No exact match.  Find the longest matching path.  We will preferentially match
    # unclaimed paths whose last two components match our desired path (which should
    # always be unique when have multi repos and the repo identifier is not blank.
    # This works pretty much for most weird issues we can find.
    #
    # Make sure that we don't choose a path that belongs to another repo.
    matchname = repo.git_label(:assume_unique => false)
    path_list.sort_by do |path,last_comps|
      matchord = longest_match_ordinal(path,repo_name)
      preference = (last_comps == matchname) ? (1 << 24) : 0
      # Sort in reverse order
      - (matchord + preference)
    end.each do |path,last_comps|
      owner_repo = Repository.find_by_path(path,:loose => true)
      if !owner_repo || owner_repo == repo
        return path
      end
    end

    # No acceptible match
    return nil
  end


  # Return the number of characters that match between (str1 and str2) << 16 + codepoint
  # of first character in str1 that doesn't match.  This is bit naive for Ruby 1.8,
  # and works properly for 1.9 with multi-byte characters (but doesn't deal with
  # codepoints more than 16 bits....
  def self.longest_match_ordinal(str1,str2)
    for result in 0..str1.length-1
      # note that str2[result]=nil if beyond end of string, which works fine!
      if str1[result] != str2[result]
        finalChar =
        case str1[result]
          when String
            str1[result].ord
          when Integer
            str1[result]
          else
            0
        end
        return (result << 16) + (finalChar & 0xFFFF)
      end
    end
    str1.length << 16
  end


  # Compute the set difference of keys between two hashes.
  def self.hash_set_diff(first_hash,second_hash)
    first_hash.inject({}) { |hash, (key,value)|
      hash[key]=value unless second_hash[key]
      hash
    }
  end


  # Promote any elements from the promotion set to the front of the input list
  def self.promote_array(input_array,promote)
    (input_array & promote) + (input_array - promote)
  end


  def self.print_out_hash(inhash)
    inhash.each {|path,common| Rails.logger.error "[GitHosting] #{path} => #{common}"}
  end


  ###############################
  ##                           ##
  ##   ADDITIONAL CLASSES      ##
  ##                           ##
  ###############################


  # Used to register errors when pulling and pushing the conf file
  class GitHostingException < StandardError
  end

  class MyLogger
    # Prefix to error messages
    ERROR_PREFIX = "[GitHosting] "

    # For errors, add our prefix to all messages
    def error(*progname, &block)
      if block_given?
        Rails.logger.error(*progname) { "#{ERROR_PREFIX}#{yield}".gsub(/\n/,"\n#{ERROR_PREFIX}") }
      else
        Rails.logger.error "#{ERROR_PREFIX}#{progname}".gsub(/\n/,"\n#{ERROR_PREFIX}")
      end
    end

    # Handle everything else with base object
    def method_missing(m, *args, &block)
      Rails.logger.send m, *args, &block
    end
  end

end
