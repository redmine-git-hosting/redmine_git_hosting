module GitHosting

  @@logger = nil
  def self.logger
    @@logger ||= RedmineGitolite::Log.get_logger(:global)
  end


  @@logger_worker = nil
  def self.logger_worker
    @@logger_worker ||= RedmineGitolite::Log.get_logger(:worker)
  end


  # Used to register errors when pulling and pushing the conf file
  class GitHostingException < StandardError
  end


  ###############################
  ##                           ##
  ##     VARIOUS ACCESSORS     ##
  ##                           ##
  ###############################


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
    RedmineGitolite::Config.gitolite_user
  end


  # This is the file portion of the url used when talking through ssh to the repository.
  def self.git_access_url(repository)
    return "#{repository_name(repository)}"
  end


  def self.http_access_url(repository)
    return "#{RedmineGitolite::Config.http_server_subdir}#{redmine_name(repository)}"
  end


  def self.repository_path(repositoryID)
    repo_name = repositoryID.is_a?(String) ? repositoryID : repository_name(repositoryID)
    return File.join(RedmineGitolite::Config.gitolite_global_storage_dir, repo_name) + ".git"
  end


  def self.redmine_name(repository)
    return File.expand_path(File.join("./", get_full_parent_path(repository), repository.git_label), "/")[1..-1]
  end


  def self.repository_name(repository, flags = nil)
    return File.expand_path(File.join("./", RedmineGitolite::Config.gitolite_redmine_storage_dir, get_full_parent_path(repository), repository.git_label(flags)), "/")[1..-1]
  end


  def self.new_repository_name(repository)
    return repository_name(repository)
  end


  def self.old_repository_name(repository)
    return "#{repository.url.gsub(RedmineGitolite::Config.gitolite_global_storage_dir, '').gsub('.git', '')}"
  end


  def self.get_full_parent_path(repository)
    return "" if !RedmineGitolite::Config.hierarchical_organisation?

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
      mytestfile = "#{scripts_dir_path}/writecheck"
      if (!File.directory?(scripts_dir_path))
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
    RedmineGitolite::Hooks.check_hooks_installed
  end


  def self.update_global_hook_params
    RedmineGitolite::Hooks.update_global_hook_params
  end


  ###############################
  ##                           ##
  ##      LOCK FUNCTIONS       ##
  ##                           ##
  ###############################


  @@lock_file = nil
  def self.lock_file
    lock_file ||= File.new(File.join(temp_dir_path, 'redmine_git_hosting_lock'), File::CREAT|File::RDONLY)
    @@lock_file = lock_file
  end


  def self.lock(action)
    if File.exist?(lock_file)
      File.open(lock_file) do |file|
        file.sync = true
        file.flock(File::LOCK_EX)
        logger_worker.debug "#{action} : get lock !"
        yield
        file.flock(File::LOCK_UN)
        logger_worker.debug "#{action} : lock released !"
      end
    else
      logger_worker.error "#{action} : cannot get lock, file does not exist #{lock_file} !"
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
    if RedmineGitolite::Config.gitolite_use_sidekiq?
      GithostingShellWorker.perform_async(data_hash)
    else
      githosting_shell = RedmineGitolite::Shell.new
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
    script_dir = RedmineGitolite::Config.gitolite_scripts_dir
    script_parent = RedmineGitolite::Config.gitolite_scripts_parent_dir

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
    tmp_dir = RedmineGitolite::Config.gitolite_temp_dir
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
    logger_worker.debug "move_repository : counted objects in repository directory '#{new_path}' : '#{output}'"
    if output.to_i == 0
      return true
    else
      return false
    end
  end


  def self.move_physical_repo(old_path, new_path, new_parent_path)
    ## CASE 1
    if old_path == new_path
      logger_worker.info "move_repository : old repository and new repository are identical '#{old_path}', nothing to do, exit !"
      return true
    end

    ## CASE 2
    if !file_exists? old_path
      logger_worker.error "move_repository : old repository '#{old_path}' does not exist, cannot move it, exit !"
      return false
    end

    ## CASE 3
    if file_exists? new_path
      if is_repository_empty?(new_path)
        logger_worker.warn "move_repository : target repository '#{new_path}' already exists and is empty, remove it..."
        begin
          GitHosting.shell %[#{shell_cmd_runner} 'rm -rf "#{new_path}"']
        rescue => e
          logger_worker.error "move_repository : removing existing target repository failed, exit !"
          return false
        end
      else
        logger_worker.warn "move_repository : target repository '#{new_path}' exists and is not empty, considered as already moved, remove the old_path"
        begin
          GitHosting.shell %[#{shell_cmd_runner} 'rm -rf "#{old_path}"']
          return true
        rescue => e
          logger_worker.error "move_repository : removing source repository directory failed, exit !"
          return false
        end
      end
    end

    logger_worker.debug "move_repository : moving Gitolite repository from '#{old_path}' to '#{new_path}'"

    if !file_exists? new_parent_path
      begin
        GitHosting.shell %[#{shell_cmd_runner} 'mkdir -p "#{new_parent_path}"']
      rescue GitHostingException
        logger_worker.error "move_repository : creation of parent path '#{new_parent_path}' failed, exit !"
        return false
      end
    end

    begin
      GitHosting.shell %[#{shell_cmd_runner} 'mv "#{old_path}" "#{new_path}"']
      logger_worker.info "move_repository : done !"
      return true
    rescue GitHostingException => e
      logger_worker.error "move_physical_repo(#{old_path}, #{new_path}) failed"
      logger_worker.error e.message
      return false
    rescue => e
      logger_worker.error "move_physical_repo(#{old_path}, #{new_path}) failed"
      logger_worker.error e.message
      logger_worker.error e.backtrace[0..4].join("\n")
      return false
    end

  end


  ## CREATE EXECUTABLE FILES
  def self.update_gitolite_scripts
    logger.info "Setting up '#{scripts_dir_path}' with scripts..."

    File.open(gitolite_admin_ssh_script_path(), "w") do |f|
      f.puts "#!/bin/sh"
      f.puts "exec ssh -T -o BatchMode=yes -o StrictHostKeyChecking=no -p #{RedmineGitolite::Config.gitolite_server_port} -i #{RedmineGitolite::Config.gitolite_ssh_private_key} \"$@\""
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

      %x[ cat '#{RedmineGitolite::Config.gitolite_ssh_private_key}' | #{shell_cmd_runner} 'cat > ~/.ssh/redmine_gitolite_admin_id_rsa_mirroring' ]
      %x[ cat '#{RedmineGitolite::Config.gitolite_ssh_public_key}'  | #{shell_cmd_runner} 'cat > ~/.ssh/redmine_gitolite_admin_id_rsa_mirroring.pub' ]
      %x[ #{shell_cmd_runner} 'chmod 600 ~/.ssh/redmine_gitolite_admin_id_rsa_mirroring' ]
      %x[ #{shell_cmd_runner} 'chmod 644 ~/.ssh/redmine_gitolite_admin_id_rsa_mirroring.pub' ]

      git_user_dir = ( %x[ #{shell_cmd_runner} "cd ~ ; pwd" ] ).chomp.strip

      %x[ echo '#!/bin/sh' | #{shell_cmd_runner} 'cat > ~/.ssh/run_gitolite_admin_ssh' ]
      %x[ echo 'exec ssh -T -o BatchMode=yes -o StrictHostKeyChecking=no -p #{RedmineGitolite::Config.gitolite_server_port} -i #{git_user_dir}/.ssh/redmine_gitolite_admin_id_rsa_mirroring "$@"' | #{shell_cmd_runner} "cat >> ~/.ssh/run_gitolite_admin_ssh" ]
      %x[ #{shell_cmd_runner} 'chmod 700 ~/.ssh/run_gitolite_admin_ssh' ]

      pubk = (%x[ cat '#{RedmineGitolite::Config.gitolite_ssh_public_key}' ]).chomp.strip
      @@mirror_pubkey = pubk.split(/[\t ]+/)[0].to_s + " " + pubk.split(/[\t ]+/)[1].to_s
    end
    @@mirror_pubkey
  end

end
