module RedmineGitolite

  module Config


    GITHUB_ISSUE = 'https://github.com/jbox-web/redmine_git_hosting/issues'
    GITHUB_WIKI  = 'https://github.com/jbox-web/redmine_git_hosting/wiki/Configuration-variables'


    def self.logger
      RedmineGitolite::Log.get_logger(:global)
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
      RedmineGitolite::ConfigRedmine.get_setting(:gitolite_user)
    end


    def self.http_server_domain
      RedmineGitolite::ConfigRedmine.get_setting(:http_server_domain)
    end


    def self.https_server_domain
      RedmineGitolite::ConfigRedmine.get_setting(:https_server_domain)
    end


    def self.gitolite_server_port
      RedmineGitolite::ConfigRedmine.get_setting(:gitolite_server_port)
    end


    def self.gitolite_ssh_private_key
      RedmineGitolite::ConfigRedmine.get_setting(:gitolite_ssh_private_key)
    end


    def self.gitolite_ssh_public_key
      RedmineGitolite::ConfigRedmine.get_setting(:gitolite_ssh_public_key)
    end


    def self.gitolite_temp_dir
      RedmineGitolite::ConfigRedmine.get_setting(:gitolite_temp_dir)
    end


    def self.gitolite_scripts_dir
      RedmineGitolite::ConfigRedmine.get_setting(:gitolite_scripts_dir)
    end


    def self.git_config_username
      RedmineGitolite::ConfigRedmine.get_setting(:git_config_username)
    end


    def self.git_config_email
      RedmineGitolite::ConfigRedmine.get_setting(:git_config_email)
    end


    GITOLITE_ADMIN_REPO = 'gitolite-admin.git'

    # Full Gitolite URL
    def self.gitolite_admin_url
      "#{gitolite_user}@localhost/#{GITOLITE_ADMIN_REPO}"
    end


    def self.gitolite_admin_dir
      File.join(get_temp_dir_path, GITOLITE_ADMIN_REPO)
    end


    def self.gitolite_commit_author
      "#{git_config_username} <#{git_config_email}>"
    end


    def self.http_root_url
      my_root_url(false)
    end


    def self.https_root_url
      my_root_url(true)
    end


    def self.my_root_url(ssl = false)
      # Remove any path from httpServer in case they are leftover from previous installations.
      # No trailing /.
      my_root_path = Redmine::Utils::relative_url_root

      if ssl && https_server_domain != ''
        server_domain = https_server_domain
      else
        server_domain = http_server_domain
      end

      my_root_url = File.join(server_domain[/^[^\/]*/], my_root_path, "/")[0..-2]

      return my_root_url
    end


    def self.gitolite_hooks_url
      return File.join("#{Setting.protocol}://", Setting.host_name, "/githooks/post-receive/redmine")
    end


    ###############################
    ##                           ##
    ##         TEMP DIR          ##
    ##                           ##
    ###############################

    @@temp_dir_path = nil
    @@previous_temp_dir_path = nil

    def self.get_temp_dir_path
      if (@@previous_temp_dir_path != gitolite_temp_dir)
        @@previous_temp_dir_path = gitolite_temp_dir
        @@temp_dir_path = File.join(gitolite_temp_dir, gitolite_user) + "/"
      end

      if !File.directory?(@@temp_dir_path)
        logger.info { "Create tmp directory : '#{@@temp_dir_path}'" }

        begin
          RedmineGitolite::GitHosting.execute_command(:local_cmd, "mkdir -p '#{@@temp_dir_path}'")
          RedmineGitolite::GitHosting.execute_command(:local_cmd, "chmod 700 '#{@@temp_dir_path}'")
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Cannot create tmp directory : '#{@@temp_dir_path}'" }
        end

      end

      return @@temp_dir_path
    end


    @@temp_dir_writeable = false

    def self.temp_dir_writeable?(opts = {})
      @@temp_dir_writeable = false if opts.has_key?(:reset) && opts[:reset] == true

      if !@@temp_dir_writeable

        logger.debug { "Testing if temp directory '#{get_temp_dir_path}' is writeable ..." }

        mytestfile = "#{get_temp_dir_path}writecheck"

        if !File.directory?(get_temp_dir_path)
          @@temp_dir_writeable = false
        else
          begin
            RedmineGitolite::GitHosting.execute_command(:local_cmd, "touch '#{mytestfile}'")
            RedmineGitolite::GitHosting.execute_command(:local_cmd, "rm '#{mytestfile}'")
            @@temp_dir_writeable = true
          rescue RedmineGitolite::GitHosting::GitHostingException => e
            @@temp_dir_writeable = false
          end
        end
      end

      return @@temp_dir_writeable
    end


    ###############################
    ##                           ##
    ##        SCRIPTS DIR        ##
    ##                           ##
    ###############################

    GITOLITE_SCRIPTS_PARENT_DIR = 'bin'

    @@scripts_dir_path = nil
    @@previous_scripts_dir_path = nil

    def self.get_scripts_dir_path
      if @@previous_scripts_dir_path != gitolite_scripts_dir
        @@previous_scripts_dir_path = gitolite_scripts_dir

        # Directory for binaries includes 'SCRIPT_PARENT' at the end.
        # Further, absolute path adds additional 'gitolite_user' component for multi-gitolite installations.
        if gitolite_scripts_dir[0, 1] == "/"
          @@scripts_dir_path = File.join(gitolite_scripts_dir, gitolite_user, GITOLITE_SCRIPTS_PARENT_DIR) + "/"
        else
          @@scripts_dir_path = Rails.root.join("plugins/redmine_git_hosting", gitolite_scripts_dir, GITOLITE_SCRIPTS_PARENT_DIR).to_s + "/"
        end
      end

      if !File.directory?(@@scripts_dir_path)
        logger.info { "Create scripts directory : '#{@@scripts_dir_path}'" }

        begin
          RedmineGitolite::GitHosting.execute_command(:local_cmd, "mkdir -p '#{@@scripts_dir_path}'")
          RedmineGitolite::GitHosting.execute_command(:local_cmd, "chmod 750 '#{@@scripts_dir_path}'")
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Cannot create scripts directory : '#{@@scripts_dir_path}'" }
        end
      end

      return @@scripts_dir_path
    end


    @@scripts_dir_writeable = false

    def self.scripts_dir_writeable?(opts = {})
      @@scripts_dir_writeable = false if opts.has_key?(:reset) && opts[:reset] == true

      if !@@scripts_dir_writeable

        logger.debug { "Testing if scripts directory '#{get_scripts_dir_path}' is writeable ..." }

        mytestfile = "#{get_scripts_dir_path}writecheck"

        if !File.directory?(get_scripts_dir_path)
          @@scripts_dir_writeable = false
        else
          begin
            RedmineGitolite::GitHosting.execute_command(:local_cmd, "touch '#{mytestfile}'")
            RedmineGitolite::GitHosting.execute_command(:local_cmd, "rm '#{mytestfile}'")
            @@scripts_dir_writeable = true
          rescue RedmineGitolite::GitHosting::GitHostingException => e
            @@scripts_dir_writeable = false
          end
        end
      end

      return @@scripts_dir_writeable
    end


    ###############################
    ##                           ##
    ##        SUDO TESTS         ##
    ##                           ##
    ###############################

    ## SUDO TEST1

    @@sudo_gitolite_to_redmine_user_stamp = nil
    @@sudo_gitolite_to_redmine_user_cached = nil

    def self.can_gitolite_sudo_to_redmine_user?
      if !@@sudo_gitolite_to_redmine_user_cached.nil? && (Time.new - @@sudo_gitolite_to_redmine_user_stamp <= 1)
        return @@sudo_gitolite_to_redmine_user_cached
      end

      logger.info { "Testing if Gitolite user '#{gitolite_user}' can sudo to Redmine user '#{redmine_user}'..." }

      if gitolite_user == redmine_user
        @@sudo_gitolite_to_redmine_user_cached = true
        @@sudo_gitolite_to_redmine_user_stamp = Time.new
        logger.info { "OK!" }
        return @@sudo_gitolite_to_redmine_user_cached
      end

      begin
        test = RedmineGitolite::GitHosting.execute_command(:shell_cmd, "sudo -n -u #{redmine_user} -i whoami")
        if test.match(/#{redmine_user}/)
          logger.info { "OK!" }
          @@sudo_gitolite_to_redmine_user_cached = true
          @@sudo_gitolite_to_redmine_user_stamp = Time.new
        else
          logger.warn { "Error while testing sudo_git_to_redmine_user" }
          @@sudo_gitolite_to_redmine_user_cached = false
          @@sudo_gitolite_to_redmine_user_stamp = Time.new
        end
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        logger.error { "Error while testing sudo_git_to_redmine_user" }
        @@sudo_gitolite_to_redmine_user_cached = false
        @@sudo_gitolite_to_redmine_user_stamp = Time.new
      end

      return @@sudo_gitolite_to_redmine_user_cached
    end


    ## SUDO TEST2

    @@sudo_redmine_to_gitolite_user_stamp = nil
    @@sudo_redmine_to_gitolite_user_cached = nil

    def self.can_redmine_sudo_to_gitolite_user?
      if !@@sudo_redmine_to_gitolite_user_cached.nil? && (Time.new - @@sudo_redmine_to_gitolite_user_stamp <= 1)
        return @@sudo_redmine_to_gitolite_user_cached
      end

      logger.info { "Testing if Redmine user '#{redmine_user}' can sudo to Gitolite user '#{gitolite_user}'..." }

      if gitolite_user == redmine_user
        @@sudo_redmine_to_gitolite_user_cached = true
        @@sudo_redmine_to_gitolite_user_stamp = Time.new
        logger.info { "OK!" }
        return @@sudo_redmine_to_gitolite_user_cached
      end

      begin
        test = RedmineGitolite::GitHosting.execute_command(:shell_cmd, "whoami")
        if test.match(/#{gitolite_user}/)
          logger.info { "OK!" }
          @@sudo_redmine_to_gitolite_user_cached = true
          @@sudo_redmine_to_gitolite_user_stamp = Time.new
        else
          logger.warn { "Error while testing sudo_web_to_gitolite_user" }
          @@sudo_redmine_to_gitolite_user_cached = false
          @@sudo_redmine_to_gitolite_user_stamp = Time.new
        end
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        logger.error { "Error while testing sudo_web_to_gitolite_user" }
        @@sudo_redmine_to_gitolite_user_cached = false
        @@sudo_redmine_to_gitolite_user_stamp = Time.new
      end

      return @@sudo_redmine_to_gitolite_user_cached
    end


    ###############################
    ##                           ##
    ##  SUDO VERSION DETECTION   ##
    ##                           ##
    ###############################

    def self.sudo_version_raw
      begin
        version = RedmineGitolite::GitHosting.execute_command(:local_cmd, "sudo -V 2>&1 | head -n1 | sed 's/^.* //g' | sed 's/[a-z].*$//g'")
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        logger.error { "Error while getting sudo version !" }
        version = "0.0.0"
      end
    end


    def self.sudo_version
      split_version    = sudo_version_raw.split(/\./)
      sudo_version     = 100*100*(split_version[0].to_i) + 100*(split_version[1].to_i) + split_version[2].to_i
      return sudo_version
    end


    ###############################
    ##                           ##
    ##      GITOLITE INFOS       ##
    ##                           ##
    ###############################

    @@gitolite_version_cached = nil
    @@gitolite_version_stamp  = nil

    def self.gitolite_version
      if !@@gitolite_version_cached.nil? && (Time.new - @@gitolite_version_stamp <= 1)
        return @@gitolite_version_cached
      end

      logger.debug { "Getting Gitolite version..." }

      begin
        version = RedmineGitolite::GitHosting.execute_command(:ssh_cmd, "#{gitolite_user}@localhost info").split("\n").first
        @@gitolite_version_cached = compute_gitolite_version(version)
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        logger.error { "Error while getting Gitolite version" }
        @@gitolite_version_cached = -1
      end

      @@gitolite_version_stamp = Time.new
      return @@gitolite_version_cached
    end


    def self.compute_gitolite_version(line)
      version = ''
      if line =~ /gitolite[ -]v?2./
         version = 2
      elsif line.include?('running gitolite3')
        version = 3
      else
        version = 0
      end
      return version
    end


    @@gitolite_banner_cached = nil
    @@gitolite_banner_stamp  = nil

    def self.gitolite_banner
      if !@@gitolite_banner_cached.nil? && (Time.new - @@gitolite_banner_stamp <= 1)
        return @@gitolite_banner_cached
      end

      logger.debug { "Getting Gitolite banner..." }

      begin
        @@gitolite_banner_cached = RedmineGitolite::GitHosting.execute_command(:ssh_cmd, "#{gitolite_user}@localhost info")
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        logger.error { "Error while getting Gitolite banner" }
        @@gitolite_banner_cached = "Error : #{e.message}"
      end

      @@gitolite_banner_stamp = Time.new
      return @@gitolite_banner_cached
    end


    def self.gitolite_command
      if gitolite_version == 2
        gitolite_command = 'gl-setup'
      elsif gitolite_version == 3
        gitolite_command = 'gitolite setup'
      else
        gitolite_command = nil
      end
      return gitolite_command
    end


    ###############################
    ##                           ##
    ##     GITOLITE WRAPPERS     ##
    ##                           ##
    ###############################

    def self.shell_cmd_script_path
      return File.join(get_scripts_dir_path, "run_shell_cmd_as_gitolite_user")
    end


    def self.git_cmd_script_path
      return File.join(get_scripts_dir_path, "run_git_cmd_as_gitolite_user")
    end


    def self.gitolite_admin_ssh_script_path
      return File.join(get_scripts_dir_path, "gitolite_admin_ssh")
    end


    def self.shell_cmd_runner
      if !File.exists?(shell_cmd_script_path)
        script_is_installed?(:shell_cmd)
      end
      return shell_cmd_script_path
    end


    def self.git_cmd_runner
      if !File.exists?(git_cmd_script_path)
        script_is_installed?(:git_cmd)
      end
      return git_cmd_script_path
    end


    def self.gitolite_admin_ssh_runner
      if !File.exists?(gitolite_admin_ssh_script_path)
        script_is_installed?(:gitolite_admin_ssh)
      end
      return gitolite_admin_ssh_script_path
    end


    ###############################
    ##                           ##
    ##      WRAPPERS INSTALL     ##
    ##                           ##
    ###############################

    GITOLITE_SCRIPTS    = [ :gitolite_admin_ssh, :git_cmd, :shell_cmd ]
    SUDO_VERSION_SWITCH = (100*100*1) + (100 * 7) + 3


    def self.script_is_installed?(script)
      self.send "#{script}_script_is_installed?"
    end


    def self.update_scripts
      updated = {}
      GITOLITE_SCRIPTS.each do |script|
        updated[script] = script_is_installed?(script)
      end

      return updated
    end


    def self.gitolite_admin_ssh_script_is_installed?
      installed = true

      if !File.exists?(gitolite_admin_ssh_script_path)
        installed = false

        logger.info { "Create script file : '#{gitolite_admin_ssh_script_path}'" }

        begin
          File.open(gitolite_admin_ssh_script_path, "w") do |f|
            f.puts "#!/bin/sh"
            f.puts "exec ssh -T -o BatchMode=yes -o StrictHostKeyChecking=no -p #{gitolite_server_port} -i #{gitolite_ssh_private_key} \"$@\""
          end

          File.chmod(0550, gitolite_admin_ssh_script_path)

          installed = true
        rescue => e
          logger.error { "Cannot create script file : '#{gitolite_admin_ssh_script_path}'" }
          installed = false
        end
      end

      return installed
    end


    def self.git_cmd_script_is_installed?
      installed = true

      if !File.exists?(git_cmd_script_path)
        installed = false

        logger.info { "Create script file : '#{git_cmd_script_path}'" }

        begin
          File.open(git_cmd_script_path, "w") do |f|
            f.puts '#!/bin/sh'
            f.puts "if [ \"\$(whoami)\" = \"#{gitolite_user}\" ] ; then"
            f.puts '  cmd=$(printf "\\"%s\\" " "$@")'
            f.puts '  cd ~'
            f.puts '  eval "git $cmd"'
            f.puts "else"
            if sudo_version < SUDO_VERSION_SWITCH
              f.puts '  cmd=$(printf "\\\\\\"%s\\\\\\" " "$@")'
              f.puts "  sudo -n -u #{gitolite_user} -i eval \"git $cmd\""
            else
              f.puts '  cmd=$(printf "\\"%s\\" " "$@")'
              f.puts "  sudo -n -u #{gitolite_user} -i eval \"git $cmd\""
            end
            f.puts 'fi'
          end

          File.chmod(0550, git_cmd_script_path)

          installed = true
        rescue => e
          logger.error { "Cannot create script file : '#{git_cmd_script_path}'" }
          installed = false
        end
      end

      return installed
    end


    def self.shell_cmd_script_is_installed?
      ##############################################################################################################################
      # So... older versions of sudo are completely different than newer versions of sudo
      # Try running sudo -i [user] 'ls -l' on sudo > 1.7.4 and you get an error that command 'ls -l' doesn't exist
      # do it on version < 1.7.3 and it runs just fine.  Different levels of escaping are necessary depending on which
      # version of sudo you are using... which just completely CRAZY, but I don't know how to avoid it
      #
      # Note: I don't know whether the switch is at 1.7.3 or 1.7.4, the switch is between ubuntu 10.10 which uses 1.7.2
      # and ubuntu 11.04 which uses 1.7.4.  I have tested that the latest 1.8.1p2 seems to have identical behavior to 1.7.4
      ##############################################################################################################################
      installed = true

      if !File.exists?(shell_cmd_script_path)
        installed = false

        RedmineGitolite::GitHosting.logger.info { "Create script file : '#{shell_cmd_script_path}'" }

        begin
          # use perl script for shell_cmd_runner so we can
          # escape output more easily
          File.open(shell_cmd_script_path, "w") do |f|
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
            if sudo_version < SUDO_VERSION_SWITCH
              f.puts '  $command =~ s/(\\\\\\\\;)/"$1"/g;'
              f.puts "  $command =~ s/'/\\\\\\\\'/g;"
            end
            f.puts '  $command =~ s/"/\\\\"/g;'
            f.puts '  exec("sudo -n -u ' + gitolite_user + ' -i eval \"$command\"");'
            f.puts '}'
          end

          File.chmod(0550, shell_cmd_script_path)

          installed = true
        rescue => e
          RedmineGitolite::GitHosting.logger.error { "Cannot create script file : '#{shell_cmd_script_path}'" }
          installed = false
        end
      end

      return installed
    end


    ###############################
    ##                           ##
    ##      MIRRORING KEYS       ##
    ##                           ##
    ###############################

    GITOLITE_DEFAULT_CONFIG_FILE       = 'gitolite.conf'
    GITOLITE_IDENTIFIER_DEFAULT_PREFIX = 'redmine_'

    GITOLITE_MIRRORING_KEYS_NAME   = "redmine_gitolite_admin_id_rsa_mirroring"
    GITOLITE_SSH_PRIVATE_KEY_PATH  = "~/.ssh/#{GITOLITE_MIRRORING_KEYS_NAME}"
    GITOLITE_SSH_PUBLIC_KEY_PATH   = "~/.ssh/#{GITOLITE_MIRRORING_KEYS_NAME}.pub"
    GITOLITE_MIRRORING_SCRIPT_PATH = '~/.ssh/run_gitolite_admin_ssh'

    @@mirroring_public_key = nil

    def self.mirroring_public_key
      if @@mirroring_public_key.nil?
        public_key = (%x[ cat '#{gitolite_ssh_public_key}' ]).chomp.strip
        @@mirroring_public_key = public_key.split(/[\t ]+/)[0].to_s + " " + public_key.split(/[\t ]+/)[1].to_s
      end

      return @@mirroring_public_key
    end


    @@mirroring_keys_installed = false

    def self.mirroring_keys_installed?(opts = {})
      @@mirroring_keys_installed = false if opts.has_key?(:reset) && opts[:reset] == true

      if !@@mirroring_keys_installed
        logger.info { "Installing Redmine Gitolite mirroring SSH keys ..." }

        begin
          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "'cat > #{GITOLITE_SSH_PRIVATE_KEY_PATH}'", :pipe_data => "'#{gitolite_ssh_private_key}'", :pipe_command => 'cat')
          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "'cat > #{GITOLITE_SSH_PUBLIC_KEY_PATH}'",  :pipe_data => "'#{gitolite_ssh_public_key}'",  :pipe_command => 'cat')

          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "'chmod 600 #{GITOLITE_SSH_PRIVATE_KEY_PATH}'")
          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "'chmod 644 #{GITOLITE_SSH_PUBLIC_KEY_PATH}'")

          git_user_dir = RedmineGitolite::GitHosting.execute_command(:shell_cmd, "'cd ~ && pwd'").chomp.strip

          command = 'exec ssh -T -o BatchMode=yes -o StrictHostKeyChecking=no -i ' + "#{git_user_dir}/.ssh/#{GITOLITE_MIRRORING_KEYS_NAME}" + ' "$@"'

          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "'cat > #{GITOLITE_MIRRORING_SCRIPT_PATH}'",  :pipe_data => "#!/bin/sh", :pipe_command => 'echo')
          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "'cat >> #{GITOLITE_MIRRORING_SCRIPT_PATH}'", :pipe_data => command, :pipe_command => 'echo')

          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "'chmod 700 #{GITOLITE_MIRRORING_SCRIPT_PATH}'")

          logger.info { "Done !" }

          @@mirroring_keys_installed = true
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Failed installing Redmine Gitolite mirroring SSH keys !" }
          logger.error { e.output }
          @@mirroring_keys_installed = false
        end
      end

      return @@mirroring_keys_installed
    end

  end
end
