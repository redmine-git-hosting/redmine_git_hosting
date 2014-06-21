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

  end
end
