module RedmineGitolite

  module Scripts


    def self.logger
      RedmineGitolite::Log.get_logger(:global)
    end


    # Puts Redmine user in cache as it should not change
    @@redmine_user = nil
    def self.redmine_user
      @@redmine_user = (%x[whoami]).chomp.strip if @@redmine_user.nil?
      @@redmine_user
    end


    def self.gitolite_user
      RedmineGitolite::Config.get_setting(:gitolite_user)
    end


    def self.gitolite_temp_dir
      RedmineGitolite::Config.get_setting(:gitolite_temp_dir)
    end


    def self.gitolite_scripts_dir
      RedmineGitolite::Config.get_setting(:gitolite_scripts_dir)
    end


    def self.gitolite_ssh_private_key
      RedmineGitolite::Config.get_setting(:gitolite_ssh_private_key)
    end


    def self.gitolite_ssh_public_key
      RedmineGitolite::Config.get_setting(:gitolite_ssh_public_key)
    end


    def self.gitolite_commit_author
      "#{git_config_username} <#{git_config_email}>"
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
        @@temp_dir_path = RedmineGitolite::GitoliteWrapper.gitolite_admin_dir
      end

      if !File.directory?(@@temp_dir_path)
        logger.info { "Create tmp directory : '#{@@temp_dir_path}'" }

        begin
          FileUtils.mkdir_p @@temp_dir_path
          FileUtils.chmod 0700, @@temp_dir_path
        rescue => e
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

        mytestfile = File.join(get_temp_dir_path, "writecheck")

        if !File.directory?(get_temp_dir_path)
          @@temp_dir_writeable = false
        else
          begin
            FileUtils.touch mytestfile
            FileUtils.rm mytestfile
            @@temp_dir_writeable = true
          rescue => e
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
          @@scripts_dir_path = File.join(gitolite_scripts_dir, gitolite_user, GITOLITE_SCRIPTS_PARENT_DIR)
        else
          @@scripts_dir_path = Rails.root.join("plugins", "redmine_git_hosting", gitolite_scripts_dir, GITOLITE_SCRIPTS_PARENT_DIR)
        end
      end

      if !File.directory?(@@scripts_dir_path)
        logger.info { "Create scripts directory : '#{@@scripts_dir_path}'" }

        begin
          FileUtils.mkdir_p @@scripts_dir_path
          FileUtils.chmod 0750, @@scripts_dir_path
        rescue => e
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

        mytestfile = File.join(get_scripts_dir_path, "writecheck")

        if !File.directory?(get_scripts_dir_path)
          @@scripts_dir_writeable = false
        else
          begin
            FileUtils.touch mytestfile
            FileUtils.rm mytestfile
            @@scripts_dir_writeable = true
          rescue => e
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
        test = GitoliteWrapper.sudo_capture('sudo', '-n', '-u', redmine_user, '-i', 'whoami')
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
        test = GitoliteWrapper.sudo_capture('whoami')
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
        output, err, code = GitHosting.execute('sudo', '-V')
      rescue => e
        logger.error { "Error while getting sudo version : #{e.output}" }
        return '0.0.0'
      end

      version = output.split("\n")[0].match(/\D+\s\D+\s([\d+\.]+)/)

      if version.nil?
        return '0.0.0'
      else
        return version[1]
      end
    end


    def self.sudo_version
      split_version    = sudo_version_raw.split(/\./)
      sudo_version     = 100*100*(split_version[0].to_i) + 100*(split_version[1].to_i) + split_version[2].to_i
      return sudo_version
    end


    ###############################
    ##                           ##
    ##     GITOLITE WRAPPERS     ##
    ##                           ##
    ###############################

    def self.git_cmd_script_path
      File.join(get_scripts_dir_path, "run_git_cmd_as_gitolite_user")
    end


    def self.git_cmd_runner
      if !File.exists?(git_cmd_script_path)
        script_is_installed?(:git_cmd)
      end
      return git_cmd_script_path
    end


    ###############################
    ##                           ##
    ##      WRAPPERS INSTALL     ##
    ##                           ##
    ###############################

    GITOLITE_SCRIPTS    = [ :git_cmd ]
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

          FileUtils.chmod 0550, git_cmd_script_path

          installed = true
        rescue => e
          logger.error { "Cannot create script file : '#{git_cmd_script_path}'" }
          installed = false
        end
      end

      return installed
    end

  end
end
