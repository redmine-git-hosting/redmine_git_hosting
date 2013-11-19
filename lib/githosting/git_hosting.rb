module GitHosting

  @@logger = nil
  def self.logger
    @@logger ||= GitoliteLogger.get_logger(:global)
  end


  # Used to register errors when pulling and pushing the conf file
  class GitHostingException < StandardError
  end


  ###############################
  ##                           ##
  ##     VARIOUS ACCESSORS     ##
  ##                           ##
  ###############################


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


  # Puts Redmine user in cache as it should not change
  @@redmine_user = nil
  def self.redmine_user
    if @@redmine_user.nil?
      @@redmine_user = (%x[whoami]).chomp.strip
    end
    return @@redmine_user
  end


  def self.redmine_user=(redmine_user)
    @@redmine_user = redmine_user
  end


  def self.gitolite_user
    GitHostingConf.gitolite_user
  end


  # This is the file portion of the url used when talking through ssh to the repository.
  def self.git_access_url(repository)
    return "#{repository_name(repository)}"
  end


  def self.http_access_url(repository)
    return "#{GitHostingConf.http_server_subdir}#{redmine_name(repository)}"
  end


  def self.repository_path(repositoryID)
    repo_name = repositoryID.is_a?(String) ? repositoryID : repository_name(repositoryID)
    return File.join(GitHostingConf.gitolite_global_storage_dir, repo_name) + ".git"
  end


  def self.redmine_name(repository)
    return File.expand_path(File.join("./", get_full_parent_path(repository), repository.git_label), "/")[1..-1]
  end


  def self.repository_name(repository, flags = nil)
    return File.expand_path(File.join("./", GitHostingConf.gitolite_redmine_storage_dir, get_full_parent_path(repository), repository.git_label(flags)), "/")[1..-1]
  end


  def self.new_repository_name(repository)
    return repository_name(repository)
  end


  def self.old_repository_name(repository)
    return "#{repository.url.gsub(GitHostingConf.gitolite_global_storage_dir, '').gsub('.git', '')}"
  end


  def self.get_full_parent_path(repository, is_file_path = false)
    return "" if !GitHostingConf.hierarchical_organisation?

    project = repository.project

    if repository.is_default?
      parent_parts = []
    else
      parent_parts = [project.identifier.to_s]
    end

    p = project
    while p.parent
      parent_id = p.parent.identifier.to_s
      parent_parts.unshift(parent_id)
      p = p.parent
    end

    return parent_parts.join("/")
  end


  def self.git_repository_exists?(repo_name)
    file_exists?(repository_path(repo_name))
  end


  ###############################
  ##                           ##
  ##       CONFIG CHECKS       ##
  ##                           ##
  ###############################


  ## TEST SCRIPTS DIRECTORY
  @@scripts_dir_writeable = nil
  def self.scripts_dir_writeable?(*option)
    @@scripts_dir_writeable = nil if option.length > 0 && option[0] == :reset
    if @@scripts_dir_writeable == nil
      mybindir = scripts_dir_path
      mytestfile = "#{mybindir}/writecheck"
      if (!File.directory?(mybindir))
        @@scripts_dir_writeable = false
      else
        %x[touch "#{mytestfile}"]
        if (!File.exists?("#{mytestfile}"))
          @@scripts_dir_writeable = false
        else
          %x[rm "#{mytestfile}"]
          @@scripts_dir_writeable = true
        end
      end
    end
    @@scripts_dir_writeable
  end


  ## SUDO TEST1
  @@sudo_gitolite_to_redmine_user_stamp = nil
  @@sudo_gitolite_to_redmine_user_cached = nil
  def self.sudo_gitolite_to_redmine_user
    if not @@sudo_gitolite_to_redmine_user_cached.nil? and (Time.new - @@sudo_gitolite_to_redmine_user_stamp <= 1)
      return @@sudo_gitolite_to_redmine_user_cached
    end
    logger.info "Testing if Gitolite user '#{gitolite_user}' can sudo to Redmine user '#{redmine_user}'..."

    if gitolite_user == redmine_user
      @@sudo_gitolite_to_redmine_user_cached = true
      @@sudo_gitolite_to_redmine_user_stamp = Time.new
      logger.info "OK!"
      return @@sudo_gitolite_to_redmine_user_cached
    end

    test = %x[#{shell_cmd_runner} sudo -inu #{redmine_user} whoami]
    if test.match(/#{redmine_user}/)
      @@sudo_gitolite_to_redmine_user_cached = true
      @@sudo_gitolite_to_redmine_user_stamp = Time.new
      logger.info "OK!"
      return @@sudo_gitolite_to_redmine_user_cached
    end

    logger.warn "Error while testing sudo_git_to_redmine_user"
    @@sudo_gitolite_to_redmine_user_cached = false
    @@sudo_gitolite_to_redmine_user_stamp = Time.new
    return @@sudo_gitolite_to_redmine_user_cached
  end


  ## SUDO TEST2
  @@sudo_redmine_to_gitolite_user_stamp = nil
  @@sudo_redmine_to_gitolite_user_cached = nil
  def self.sudo_redmine_to_gitolite_user
    if not @@sudo_redmine_to_gitolite_user_cached.nil? and (Time.new - @@sudo_redmine_to_gitolite_user_stamp <= 1)
      return @@sudo_redmine_to_gitolite_user_cached
    end
    logger.info "Testing if Redmine user '#{redmine_user}' can sudo to Gitolite user '#{gitolite_user}'..."

    if gitolite_user == redmine_user
      @@sudo_redmine_to_gitolite_user_cached = true
      @@sudo_redmine_to_gitolite_user_stamp = Time.new
      logger.info "OK!"
      return @@sudo_redmine_to_gitolite_user_cached
    end

    test = %x[#{shell_cmd_runner} whoami]
    if test.match(/#{gitolite_user}/)
      @@sudo_redmine_to_gitolite_user_cached = true
      @@sudo_redmine_to_gitolite_user_stamp = Time.new
      logger.info "OK!"
      return @@sudo_redmine_to_gitolite_user_cached
    end

    logger.warn "Error while testing sudo_web_to_gitolite_user"
    @@sudo_redmine_to_gitolite_user_cached = false
    @@sudo_redmine_to_gitolite_user_stamp = Time.new
    return @@sudo_redmine_to_gitolite_user_cached
  end


  ## GET GITOLITE VERSION
  def self.gitolite_version
    stdin, stdout, stderr = Open3.popen3("#{gitolite_admin_ssh_runner} #{gitolite_user}@localhost info")

    if !stderr.readlines.blank?
      return -1
    else
      version = stdout.readlines
      version.each do |line|
        if line =~ /gitolite[ -]v?2./
          return 2
        elsif line.include?('running gitolite3')
          return 3
        else
          return 0
        end
      end
    end
  end


  ## GET GITOLITE BANNER
  def self.gitolite_banner
    stdin, stdout, stderr = Open3.popen3("#{gitolite_admin_ssh_runner} #{gitolite_user}@localhost info")

    errors = stderr.readlines
    if !errors.blank?
      return errors.join("")
    else
      return stdout.readlines.join("")
    end
  end


  ###############################
  ##                           ##
  ##       GLOBAL HOOKS        ##
  ##                           ##
  ###############################


  def self.check_hooks_installed
    installed = false
    if lock
      installed = GitoliteHooks.check_hooks_installed
      unlock
    end
    installed
  end


  def self.update_global_hook_params
    if lock
      updated = GitoliteHooks.update_global_hook_params
      unlock
    end
    updated
  end


  def self.setup_hooks(projects = nil)
    if lock
      installed = GitoliteHooks.setup_hooks(projects)
      unlock
    end
    installed
  end


  ###############################
  ##                           ##
  ##      LOCK FUNCTIONS       ##
  ##                           ##
  ###############################


  @@lock_file = nil
  def self.lock
    is_locked = false
    retries = GitHostingConf.gitolite_lock_wait_time

    if @@lock_file.nil?
      @@lock_file = File.new(File.join(temp_dir_path, 'redmine_git_hosting_lock'), File::CREAT|File::RDONLY)
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
  ##     GITOLITE WRAPPERS     ##
  ##                           ##
  ###############################


  def self.shell_cmd_runner
    if !File.exists?(shell_cmd_script_path)
      update_gitolite_scripts
    end
    return shell_cmd_script_path
  end


  def self.git_cmd_runner
    if !File.exists?(git_cmd_script_path)
      update_gitolite_scripts
    end
    return git_cmd_script_path
  end


  def self.gitolite_admin_ssh_runner
    if !File.exists?(gitolite_admin_ssh_script_path)
      update_gitolite_scripts
    end
    return gitolite_admin_ssh_script_path
  end


  def self.shell_cmd_script_path
    return File.join(scripts_dir_path, "run_shell_cmd_as_gitolite_user")
  end


  def self.git_cmd_script_path
    return File.join(scripts_dir_path, "run_git_cmd_as_gitolite_user")
  end


  def self.gitolite_admin_ssh_script_path
    return File.join(scripts_dir_path, "gitolite_admin_ssh")
  end


  def self.resync_gitolite(data_hash)
    sidekiq_mode = false
    if sidekiq_mode == true
      GithostingShellWorker.perform_async(data_hash)
    else
      githosting_shell = Githosting::Shell.new
      githosting_shell.handle_command(data_hash[:command], data_hash[:object])
    end
  end


  # Check to see if the given repository exists or not in DB...
  def self.git_repository_exists_in_db?(repo_name)
    if !Repository.find_by_path(repository_path(repo_name)).nil?
      return true
    else
      return false
    end
  end


  ###############################
  ##                           ##
  ##      SHELL FUNCTIONS      ##
  ##                           ##
  ###############################


  ## GET OR CREATE BIN DIR
  @@scripts_dir_path = nil
  @@previous_scripts_dir_path = nil
  def self.scripts_dir_path
    script_dir = GitHostingConf.gitolite_scripts_dir
    script_parent = GitHostingConf.gitolite_scripts_parent_dir

    if @@previous_scripts_dir_path != script_dir

      @@previous_scripts_dir_path = script_dir
      @@scripts_dir_writeable = nil

      # Directory for binaries includes 'SCRIPT_PARENT' at the end.
      # Further, absolute path adds additional 'gitolite_user' component for multi-gitolite installations.
      if script_dir[0,1] == "/"
        @@scripts_dir_path = File.join(script_dir, gitolite_user, script_parent) + "/"
      else
        @@scripts_dir_path = Rails.root.join("plugins/redmine_git_hosting", script_dir, script_parent).to_s + "/"
      end
    end

    if !File.directory?(@@scripts_dir_path)
      logger.info "############ TEST SCRIPT DIR ############"
      logger.info "Creating bin directory :'#{@@scripts_dir_path}' with owner : '#{redmine_user}'"
      begin
        %x[mkdir -p "#{@@scripts_dir_path}"]
        %x[chmod 750 "#{@@scripts_dir_path}"]
        %x[chown #{redmine_user} "#{@@scripts_dir_path}"]
      rescue => e
        logger.error "Cannot create bin directory: #{@@scripts_dir_path}"
        logger.error e.message
      end
    end
    return @@scripts_dir_path
  end


  ## GET OR CREATE TEMP DIR
  @@temp_dir_path = nil
  @@previous_temp_dir_path = nil
  def self.temp_dir_path
    tmp_dir = GitHostingConf.gitolite_temp_dir
    if (@@previous_temp_dir_path != tmp_dir)
      @@previous_temp_dir_path = tmp_dir
      @@temp_dir_path = File.join(tmp_dir, gitolite_user) + "/"
    end
    if !File.directory?(@@temp_dir_path)
      %x[mkdir -p "#{@@temp_dir_path}"]
      %x[chmod 700 "#{@@temp_dir_path}"]
      %x[chown #{redmine_user} "#{@@temp_dir_path}"]
    end
    return @@temp_dir_path
  end


  ## DO SHELL COMMAND
  def self.shell(command)
    begin
      my_command = "#{command} 2>&1"
      result = %x[#{my_command}].chomp
      code = $?.exitstatus
    rescue Exception => e
      result = e.message
      code = -1
    end
    if code != 0
      logger.error "Command failed (return #{code}): #{command}"
      message = "  " + result.split("\n").join("\n  ")
      logger.error message
      raise GitHostingException, "Shell Error"
    end
  end


  ## TEST IF FILE EXIST ON GITOLITE SIDE
  def self.file_exists?(filename)
    (%x[#{shell_cmd_runner} test -r '#{filename}' && echo 'yes' || echo 'no']).match(/yes/) ? true : false
  end


  def self.is_repository_empty?(new_path)
    output = %x[ #{shell_cmd_runner} 'find "#{new_path}"/objects -type f | wc -l' ].chomp.gsub('\n', '')
    GitoliteLogger.get_logger(:worker).debug "move_repository : counted objects in repository directory '#{new_path}' : '#{output}'"
    if output.to_i == 0
      return true
    else
      return false
    end
  end


  # This routine moves a repository in the gitolite repository structure.
  def self.move_physical_repo(old_name,new_name)
    begin
      logger.info "Moving gitolite repository from '#{old_name}.git' to '#{new_name}.git'"

      if git_repository_exists? new_name
        logger.error "Repository already exists at #{new_name}.git!  Moving to recycle bin to avoid overwrite."
        GitoliteRecycle.move_repository_to_recycle new_name
      end

      # physicaly move the repo BEFORE committing/pushing conf changes to gitolite admin repo
      prefix = new_name[/.*(?=\/)/] # Complete directory path (if exists) without trailing '/'
      if prefix
        # Has subdirectory.  Must construct destination directory
        repo_prefix = File.join(GitHostingConf.gitolite_global_storage_dir, prefix)
        shell %[#{shell_cmd_runner} mkdir -p '#{repo_prefix}']
      end
      old_path = repository_path(old_name)
      new_path = repository_path(new_name)
      shell %[#{shell_cmd_runner} 'mv "#{old_path}" "#{new_path}"']

      # If any empty directories left behind, try to delete them.  Ignore failure.
      old_prefix = old_name[/.*?(?=\/)/] # Top-level old directory without trailing '/'
      if old_prefix
        repo_subpath = File.join(GitHostingConf.gitolite_global_storage_dir, old_prefix)
        result = %x[#{shell_cmd_runner} find '#{repo_subpath}' -depth -type d ! -regex '.*\.git/.*' -empty -delete -print].chomp.split("\n")
        result.each { |dir| logger.info "Removing empty repository subdirectory : #{dir}"}
      end
    rescue GitHostingException => e
      logger.error "move_physical_repo(#{old_name},#{new_name}) failed"
      logger.error e.message
    rescue => e
      logger.error e.message
      logger.error e.backtrace[0..4].join("\n")
      logger.error "move_physical_repo(#{old_name},#{new_name}) failed"
    end

  end


  ## CREATE EXECUTABLE FILES
  def self.update_gitolite_scripts
    logger.info "Setting up '#{scripts_dir_path}' with scripts..."

    File.open(gitolite_admin_ssh_script_path(), "w") do |f|
      f.puts "#!/bin/sh"
      f.puts "exec ssh -T -o BatchMode=yes -o StrictHostKeyChecking=no -p #{GitHostingConf.gitolite_server_port} -i #{GitHostingConf.gitolite_ssh_private_key} \"$@\""
    end if !File.exists?(gitolite_admin_ssh_script_path())

    ##############################################################################################################################
    # So... older versions of sudo are completely different than newer versions of sudo
    # Try running sudo -i [user] 'ls -l' on sudo > 1.7.4 and you get an error that command 'ls -l' doesn't exist
    # do it on version < 1.7.3 and it runs just fine.  Different levels of escaping are necessary depending on which
    # version of sudo you are using... which just completely CRAZY, but I don't know how to avoid it
    #
    # Note: I don't know whether the switch is at 1.7.3 or 1.7.4, the switch is between ubuntu 10.10 which uses 1.7.2
    # and ubuntu 11.04 which uses 1.7.4.  I have tested that the latest 1.8.1p2 seems to have identical behavior to 1.7.4
    ##############################################################################################################################
    sudo_version_str    = %x[ sudo -V 2>&1 | head -n1 | sed 's/^.* //g' | sed 's/[a-z].*$//g' ]
    split_version       = sudo_version_str.split(/\./)
    sudo_version        = 100*100*(split_version[0].to_i) + 100*(split_version[1].to_i) + split_version[2].to_i
    sudo_version_switch = (100*100*1) + (100 * 7) + 3

    File.open(git_cmd_script_path(), "w") do |f|
      f.puts '#!/bin/sh'
      f.puts "if [ \"\$(whoami)\" = \"#{gitolite_user}\" ] ; then"
      f.puts '  cmd=$(printf "\\"%s\\" " "$@")'
      f.puts '  cd ~'
      f.puts '  eval "git $cmd"'
      f.puts "else"
      if sudo_version < sudo_version_switch
        f.puts '  cmd=$(printf "\\\\\\"%s\\\\\\" " "$@")'
        f.puts "  sudo -u #{gitolite_user} -i eval \"git $cmd\""
      else
        f.puts '  cmd=$(printf "\\"%s\\" " "$@")'
        f.puts "  sudo -u #{gitolite_user} -i eval \"git $cmd\""
      end
      f.puts 'fi'
    end if !File.exists?(git_cmd_script_path())

    # use perl script for shell_cmd_runner so we can
    # escape output more easily
    File.open(shell_cmd_script_path(), "w") do |f|
      f.puts '#!/usr/bin/perl'
      f.puts ''
      f.puts 'my $command = join(" ", @ARGV);'
      f.puts ''
      f.puts 'my $user = `whoami`;'
      f.puts 'chomp $user;'
      f.puts 'if ($user eq "' + gitolite_user + '")'
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
      f.puts '  exec("sudo -u ' + gitolite_user + ' -i eval \"$command\"");'
      f.puts '}'
    end if !File.exists?(shell_cmd_script_path())

    File.chmod(0550, git_cmd_script_path())
    File.chmod(0550, shell_cmd_script_path())
    File.chmod(0550, gitolite_admin_ssh_script_path())
    %x[chown #{redmine_user} -R "#{scripts_dir_path}"]
  end


  ## HANDLE MIRROR KEYS
  @@mirror_pubkey = nil
  def self.mirror_push_public_key
    if @@mirror_pubkey.nil?
      logger.info "Install Redmine Gitolite mirroring SSH key"

      %x[ cat '#{GitHostingConf.gitolite_ssh_private_key}' | #{shell_cmd_runner} 'cat > ~/.ssh/redmine_gitolite_admin_id_rsa_mirroring' ]
      %x[ cat '#{GitHostingConf.gitolite_ssh_public_key}'  | #{shell_cmd_runner} 'cat > ~/.ssh/redmine_gitolite_admin_id_rsa_mirroring.pub' ]
      %x[ #{shell_cmd_runner} 'chmod 600 ~/.ssh/redmine_gitolite_admin_id_rsa_mirroring' ]
      %x[ #{shell_cmd_runner} 'chmod 644 ~/.ssh/redmine_gitolite_admin_id_rsa_mirroring.pub' ]

      git_user_dir = ( %x[ #{shell_cmd_runner} "cd ~ ; pwd" ] ).chomp.strip

      %x[ echo '#!/bin/sh' | #{shell_cmd_runner} 'cat > ~/.ssh/run_gitolite_admin_ssh' ]
      %x[ echo 'exec ssh -T -o BatchMode=yes -o StrictHostKeyChecking=no -p #{GitHostingConf.gitolite_server_port} -i #{git_user_dir}/.ssh/redmine_gitolite_admin_id_rsa_mirroring "$@"' | #{shell_cmd_runner} "cat >> ~/.ssh/run_gitolite_admin_ssh" ]
      %x[ #{shell_cmd_runner} 'chmod 700 ~/.ssh/run_gitolite_admin_ssh' ]

      pubk = (%x[ cat '#{GitHostingConf.gitolite_ssh_public_key}' ]).chomp.strip
      @@mirror_pubkey = pubk.split(/[\t ]+/)[0].to_s + " " + pubk.split(/[\t ]+/)[1].to_s
    end
    @@mirror_pubkey
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
    repo_dir = File.join(temp_dir_path, GitHosting::GitoliteConfig::ADMIN_REPO)

    # If preexisting directory exists, try to clone and merge....
    if (File.exists? "#{repo_dir}") && (File.exists? "#{repo_dir}/.git") && (File.exists? "#{repo_dir}/keydir") && (File.exists? "#{repo_dir}/conf")
      logger.debug "Fetching changes from Gitolite Admin repository to '#{repo_dir}'"

      begin
        shell %[env GIT_SSH=#{gitolite_admin_ssh_runner} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' fetch]
        shell %[env GIT_SSH=#{gitolite_admin_ssh_runner} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' merge FETCH_HEAD]

        # unmerged changes=> non-empty return
        return_val = %x[env GIT_SSH=#{gitolite_admin_ssh_runner} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' status --short].empty?

        if (return_val)
          shell %[chmod 700 "#{repo_dir}"]
          # Make sure we have our hooks setup
          GitoliteHooks.check_hooks_installed
          return return_val
        else
          # The attempt to merge can cause a weird failure mode when interacting with cron jobs that clean out old
          # files in /tmp.  The issue is that keys in the keydir can go idle and get deleted.  Then, when we merge we
          # create an admin repo minus those keys (including the admin key!).  Only a RESYNC_ALL operation will
          # actually fix.      Thus, we never return "have uncommitted changes", but instead fail the merge and reclone.
          #
          # 04/23/12
          # --KUBI--
          logger.error "Seems to be unmerged changes! Going to delete and reclone for safety."
          logger.error "May need to execute RESYNC_ALL to fix whatever caused pending changes." unless resync_all_flag
        end
      rescue => e
        logger.error "Repository fetch and merge failed -- trying to delete and reclone Gitolite Admin repository."
        logger.error e.message
      end
    end

    logger.info "Cloning Gitolite Admin repository to '#{repo_dir}'"
    begin
      shell %[rm -rf "#{repo_dir}"]
      shell %[env GIT_SSH=#{gitolite_admin_ssh_runner} git clone ssh://#{gitolite_user}@localhost/gitolite-admin.git #{repo_dir}]
      shell %[chmod 700 "#{repo_dir}"]

      # Make sure we have our hooks setup
      GitoliteHooks.check_hooks_installed

      return true # On master (fresh clone)
    rescue => e
      logger.error e.message
      logger.error "Cannot clone Gitolite Admin repository. Try to fix it!"

      begin
        # Try to repair admin access.
        fixup_gitolite_admin

        logger.info "Recloning Gitolite Admin repository to '#{repo_dir}'"
        shell %[rm -rf "#{repo_dir}"]
        shell %[env GIT_SSH=#{gitolite_admin_ssh_runner} git clone ssh://#{gitolite_user}@localhost/gitolite-admin.git #{repo_dir}]
        shell %[chmod 700 "#{repo_dir}"]

        # Make sure we have our hooks setup
        GitoliteHooks.check_hooks_installed

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

    logger.warn "Attempting to restore Gitolite Admin key :"

    begin
      if gitolite_version == 2
        gitolite_command = 'gl-admin-push -f'
      elsif gitolite_version == 3
        gitolite_command = 'gitolite push -f'
      else
        raise GitHostingException, "Unknown Gitolite Version"
      end

      repo_dir  = File.join(Dir.tmpdir, "fixrepo", gitolite_user, GitHosting::GitoliteConfig::ADMIN_REPO)
      conf_file = File.join(repo_dir, "conf", gitolite_conf)
      keydir    = File.join(repo_dir, 'keydir')

      tmp_conf_dir  = File.join(Dir.tmpdir, "fixconf", gitolite_user)
      tmp_conf_file = File.join(tmp_conf_dir, gitolite_conf)

      admin_repo = "#{GitHostingConf.gitolite_global_storage_dir}/#{GitHosting::GitoliteConfig::ADMIN_REPO}"

      logger.warn "Cloning Gitolite Admin repository '#{admin_repo}' directly as '#{gitolite_user}' in '#{repo_dir}'"

      shell %[rm -rf "#{repo_dir}"] if File.exists?(repo_dir)
      shell %[#{shell_cmd_runner} git clone #{admin_repo} #{repo_dir}]

      # Load up existing conf file
      shell %[mkdir -p #{tmp_conf_dir}]
      shell %[mkdir -p #{keydir}]

      shell %[#{shell_cmd_runner} 'cat #{conf_file}' | cat > #{tmp_conf_file}]
      conf = GitoliteConfig.new(tmp_conf_file)

      # copy key into home directory...
      shell %[cat #{GitHostingConf.gitolite_ssh_public_key} | #{shell_cmd_runner} 'cat > ~/id_rsa.pub']

      # Locate any keys that match redmine_git_hosting key
      raw_admin_key_matches = %x[#{shell_cmd_runner} 'find #{keydir} -type f -exec cmp -s ~/id_rsa.pub {} \\; -print'].chomp.split("\n")

      # Reorder them by putting preferred keys first
      preferred = ["#{GitHosting::GitoliteConfig::DEFAULT_ADMIN_KEY_NAME}", "id_rsa.pub"]
      raw_admin_key_matches = promote_array(raw_admin_key_matches, preferred)

      # Remove all but first one
      first_match = nil
      raw_admin_key_matches.each do |name|
        # Take basename and remove as many ".pub" as you can
        working_basename = /^(.*\/)?([^\/]*?)(\.pub)*$/.match(name)[2]
        if first_match || ("#{working_basename}.pub" != File.basename(name))
          logger.warn "Removing duplicate administrative key '#{File.basename(name)}' from keydir"
          shell %[#{shell_cmd_runner} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' rm #{name}]
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
          logger.warn "Removing orphan administrative key '#{keyname}' from Gitolite config file"
          conf.delete_admin_keys keyname
        end
      end

      logger.warn "Establishing '#{new_admin_key_name}.pub' as the Gitolite Admin key"

      # Add selected key to front of admin list
      admin_keys = ([new_admin_key_name] + conf.get_admin_keys).uniq
      if (admin_keys.length > 1)
        logger.warn "Additional administrative key(s): #{admin_keys[1..-1].map{|x| "'#{x}.pub'"}.join(', ')}"
      end
      conf.set_admin_keys admin_keys
      conf.save

      shell %[cat #{tmp_conf_file} | #{shell_cmd_runner} 'cat > #{conf_file}']
      shell %[#{shell_cmd_runner} 'mv ~/id_rsa.pub #{keydir}/#{new_admin_key_name}.pub']
      shell %[#{shell_cmd_runner} "git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' add keydir/*"]
      shell %[#{shell_cmd_runner} "git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' add conf/#{gitolite_conf}"]
      shell %[#{shell_cmd_runner} "git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' config user.email '#{Setting.mail_from}'"]
      shell %[#{shell_cmd_runner} "git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' config user.name 'Redmine'"]
      shell %[#{shell_cmd_runner} "git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' commit -m 'Updated by Redmine: Emergency repair of Gitolite Admin key'"]

      logger.warn "Pushing fixes using '#{gitolite_command}'"
      shell %[#{shell_cmd_runner} "cd #{repo_dir}; #{gitolite_command}"]

      %x[#{shell_cmd_runner} 'rm -rf "#{File.join(Dir.tmpdir,'fixrepo')}"']
      %x[rm -rf "#{File.join(Dir.tmpdir,'fixconf')}"]
      logger.warn "Success!"
      logger.warn ""
    rescue => e
      logger.error "Failed to reestablish Gitolite Admin key."
      logger.error e.message
      logger.error e.backtrace.join("\n")
      %x[#{shell_cmd_runner} 'rm -f ~/id_rsa.pub']
      %x[#{shell_cmd_runner} 'rm -rf "#{File.join(Dir.tmpdir, 'fixrepo')}"']
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
    repo_dir = File.join(temp_dir_path, GitHosting::GitoliteConfig::ADMIN_REPO)

    if (!resyncing)
      logger.info "Committing changes to Gitolite Admin repository"
      message = "Updated by Redmine"
    else
      logger.warn "Committing corrections to Gitolite Admin repository"
      message = "Updated by Redmine : Corrections discovered during RESYNC_ALL"
    end

    # commit / push changes to gitolite admin repo
    begin
      shell %[env GIT_SSH=#{gitolite_admin_ssh_runner} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' add keydir/*]
      shell %[env GIT_SSH=#{gitolite_admin_ssh_runner} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' add conf/#{gitolite_conf}]
      shell %[env GIT_SSH=#{gitolite_admin_ssh_runner} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' config user.email '#{Setting.mail_from}']
      shell %[env GIT_SSH=#{gitolite_admin_ssh_runner} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' config user.name 'Redmine']
      shell %[env GIT_SSH=#{gitolite_admin_ssh_runner} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' commit -a -m '#{message}']
      shell %[env GIT_SSH=#{gitolite_admin_ssh_runner} git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' push -u origin master]
    rescue => e
      logger.error "Problems committing changes to Gitolite Admin repository!! Probably requires human intervention"
      logger.error e.message
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

    if flags[:resync_all]
      logger.info "Executing RESYNC_ALL operation on Gitolite configuration"
      projects = Project.active_or_archived.find(:all, :include => reposym)
    elsif flags[:delete]
      # When delete, want to recompute users, so need to go through all projects
      logger.info "Executing DELETE operation (resync keys, remove dead repositories)"
      projects = args[0]
    elsif flags[:archive]
      # When archive, want to recompute users, so need to go through all projects
      logger.info "Executing ARCHIVE operation (remove keys)"
      projects = Project.active_or_archived.find(:all, :include => reposym)
    elsif flags[:descendants]
      logger.info "Executing RESYNC_ALL operation on Gitolite configuration for projects and descendants"
      if Project.method_defined?(:self_and_descendants)
        projects = (args.flatten.select{|p| p.is_a?(Project)}).collect{|p| p.self_and_descendants}.flatten
      else
        projects = Project.active_or_archived.find(:all, :include => reposym)
      end
    else
      projects = args.flatten.select{|p| p.is_a?(Project)}
      if projects.length > 0
        logger.debug "No flags set, RESYNC_KEYS for projects (number: '#{projects.length}')"
      end
    end

    # Only take projects that have Git repos.
    if flags[:delete]
      git_projects = projects
    else
      git_projects = projects.uniq.select{|p| p.gitolite_repos.any?}
    end

    return if git_projects.empty?

    if(defined?(@@recursionCheck))
      if(@@recursionCheck)
        # This shouldn't happen any more -- log as error
        logger.error "update_repositories() exited with positive recursionCheck flag!"
        return
      end
    end

    @@recursionCheck = true

    # Grab actual lock
    if !lock
      logger.error "update_repositories() exited without acquiring lock!"
      @@recursionCheck = false
      return
    end

    begin
      # Make sure we have gitolite-admin cloned.
      # If have uncommitted changes, reflect in "changed" flag.
      changed = !clone_or_pull_gitolite_admin(flags[:resync_all])

      # Get directory for the gitolite-admin
      repo_dir = File.join(temp_dir_path, "gitolite-admin")

      logger.info "Updating key directory for projects : '#{git_projects.join ', '}'"

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
          active_keys = RepositoryDeploymentCredential.active.select(&:honored?).map(&:gitolite_public_key).uniq
          cur_token = cur_user

          # Remove inactive Deployment Credentials
          RepositoryDeploymentCredential.inactive.each {|cred| RepositoryDeploymentCredential.destroy(cred.id)}
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
          logger.info "Removing Redmine key from Gitolite : '#{keyname}'"
          %x[git --git-dir='#{repo_dir}/.git' --work-tree='#{repo_dir}' rm keydir/#{keyname}]
          changed = true
        end

        # Add missing keys to the keydir
        active_keys.each do |key|
          keyname = "#{key.identifier}.pub"
          unless old_keynames.include?(keyname)
            filename = File.join(keydir, keyname)
            logger.info "Adding Redmine key to Gitolite : '#{keyname}'"
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
            logger.info "Removing #{orphanString}Redmine key from Gitolite : '#{keyname}'"
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

        proj.gitolite_repos.each do |repo|
          repo_name = repository_name(repo)

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
              logger.info "Creating new entry in '#{gitolite_conf}' for '#{repo_name}'"
            else
              logger.info "Restoring existing entry in '#{gitolite_conf}' for '#{repo_name}'"
            end
          elsif closest_entry != repo_name
            # MOVE case.
            logger.info "Moving entry '#{closest_entry}' to '#{repo_name}' in '#{gitolite_conf}'."
            conf.rename_repo(closest_entry,repo_name)
          else
            # NORMAL case. Have entry with correct name.
            if !my_repos[repo_name]
              logger.info "Missing or misnamed repository for existing Gitolite entry : '#{repo_name}'."
            else
              logger.debug "Using existing entry '#{repo_name}' in '#{gitolite_conf}'"
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
              logger.info "Let Gitolite create empty repository : '#{repository_path(repo_name)}'"
            end
          elsif my_repos[closest_entry]
            # We have a repository that matches the entry we used above.  Move this one to match if necessary
            # If closest_entry == repo_name, this is a NORMAL case (do nothing!)
            # If closest_entry != repo_name, this is the MOVE case.
            if closest_entry != repo_name
              move_physical_repo(closest_entry, repo_name)
            else
              logger.info "Using existing Gitolite repository : '#{repository_path(repo_name)}' for update"
            end
          elsif my_repos[repo_name]
            # Existing repo with right name.  We know that there wasn't a corresponding gitolite.conf entry....
            logger.info "Restoring existing Gitolite repository : '#{repository_path(repo_name)}' for update"
          else
            # Of the repos in my_repo with a matching base name, only steal away those not already controlled
            # by gitolite.conf.  The one reasonable case here is if (for some reason) a move was properly executed
            # in gitolite.conf but the repo didn't get moved.
            closest_repo = closest_path(hash_set_diff(my_repos, total_entries), repo_name, repo)
            if !closest_repo
              # Attempt to recover repository from recycle_bin, if present.  Else, create new repository.
              if !GitoliteRecycle.recover_repository_if_present repo_name
                force_change = true
                logger.info "Let Gitolite create empty repository : '#{repository_path(repo_name)}'"
              end
            else
              logger.info "Claiming orphan repository '#{repository_path(closest_repo)}' in Gitolite repositories."
              move_physical_repo(closest_repo,repo_name)
            end
          end

          # Update repository url and root_url if necessary
          target_url = repository_path(repo_name)
          if repo.url != target_url || repo.root_url != target_url
            logger.warn "Updating internal access path to '#{target_url}'."
            repo.url = repo.root_url = target_url
            repo.save
          end

          # If this is an active (non-archived) project, then update gitolite entry.  Add GIT_DAEMON_KEY.
          if proj.active?
            if proj.module_enabled?(:repository)
              # Get deployment keys (could be empty)
              read_user_keys  = []
              write_user_keys = []

              repo.repository_deployment_credentials.active.select(&:honored?).each do |cred|
                if cred.allowed_to?(:commit_access)
                  write_user_keys << cred.gitolite_public_key.identifier
                elsif cred.allowed_to?(:view_changesets)
                  read_user_keys << cred.gitolite_public_key.identifier
                end
              end

              # Add project-specific keys
              write_user_keys += proj_write_user_keys
              read_user_keys += proj_read_user_keys

              # If no redmine keys, mark with dummy key before others to keep control on repo
              if read_user_keys.empty? && write_user_keys.empty?
                read_user_keys.push GitoliteConfig::DUMMY_REDMINE_KEY
              end

              # Git daemon support
              if (repo.extra.git_daemon == 1 || repo.extra.git_daemon == nil ) && repo.project.is_public
                read_user_keys.push GitoliteConfig::GIT_DAEMON_KEY
              end

              # Remove previous redmine keys, then add new keys
              # By doing things this way, we leave non-redmine keys alone
              # Note -- delete_redmine_keys() will also remove the GIT_DAEMON_KEY for repos with redmine keys
              # (to be put back as above, when appropriate).
              conf.delete_redmine_keys repo_name
              conf.add_read_user repo_name, read_user_keys.uniq.sort
              conf.add_write_user repo_name, write_user_keys.uniq.sort
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
              logger.info "Deleting #{orphanString}Gitolite repository '#{repo_name}' from '#{gitolite_conf}'"
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
      GitoliteHooks.setup_hooks_params((flags[:resync_all] || flags[:resync_hooks]) ? git_projects : new_projects)

    rescue GitHostingException => e
      logger.error "update_repositories() failed"
      logger.error e.message
    rescue => e
      logger.error e.message
      logger.error e.backtrace[0..4].join("\n")
      logger.error "update_repositories() failed"
    end

    unlock()
    @@recursionCheck = false
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
  def self.closest_path(path_list,repo_name, repo)
    # most common case: have exact matching path
    return repo_name if path_list[repo_name]

    # Special handling if repository name could change with Repository.repo_ident_unique?
    if multi_repos? && !repo.identifier.blank?
      # See if we find match by merely changing value of Repository.repo_ident_unique?
      repo_name_alt = repository_name(repo, :assume_unique => !Repository.repo_ident_unique?)
      if path_list[repo_name_alt]
        # Make sure that this doesn't belong to another repo
        owner_repo = Repository.find_by_path(repo_name_alt, :loose => true)
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
    path_list.sort_by do |path, last_comps|
      matchord = longest_match_ordinal(path, repo_name)
      preference = (last_comps == matchname) ? (1 << 24) : 0
      # Sort in reverse order
      - (matchord + preference)
    end.each do |path, last_comps|
      owner_repo = Repository.find_by_path(path, :loose => true)
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
  def self.longest_match_ordinal(str1, str2)
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
  def self.hash_set_diff(first_hash, second_hash)
    first_hash.inject({}) { |hash, (key, value)|
      hash[key] = value unless second_hash[key]
      hash
    }
  end


  # Promote any elements from the promotion set to the front of the input list
  def self.promote_array(input_array,promote)
    (input_array & promote) + (input_array - promote)
  end


  def self.print_out_hash(inhash)
    inhash.each{ |path,common| Rails.logger.error "#{path} => #{common}" }
  end

end
