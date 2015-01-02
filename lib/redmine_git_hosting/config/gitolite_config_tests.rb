module RedmineGitHosting::Config

  module GitoliteConfigTests

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods


      ###############################
      ##                           ##
      ##         TEMP DIR          ##
      ##                           ##
      ###############################

      @temp_dir_path = nil
      @previous_temp_dir_path = nil

      def create_temp_dir
        if @previous_temp_dir_path != gitolite_temp_dir
          @previous_temp_dir_path = gitolite_temp_dir
          @temp_dir_path = gitolite_admin_dir
        end

        if !File.directory?(@temp_dir_path)
          logger.info("Create tmp directory : '#{@temp_dir_path}'")
          begin
            FileUtils.mkdir_p @temp_dir_path
            FileUtils.chmod 0700, @temp_dir_path
          rescue => e
            logger.error("Cannot create tmp directory : '#{@temp_dir_path}'")
          end
        end

        @temp_dir_path
      end


      @temp_dir_writeable = false

      def temp_dir_writeable?(opts = {})
        @temp_dir_writeable = false if opts.has_key?(:reset) && opts[:reset] == true

        if !@temp_dir_writeable
          logger.debug("Testing if temp directory '#{create_temp_dir}' is writeable ...")
          mytestfile = File.join(create_temp_dir, "writecheck")
          if !File.directory?(create_temp_dir)
            @temp_dir_writeable = false
          else
            begin
              FileUtils.touch mytestfile
              FileUtils.rm mytestfile
            rescue => e
              @temp_dir_writeable = false
            else
              @temp_dir_writeable = true
            end
          end
        end

        @temp_dir_writeable
      end


      ###############################
      ##                           ##
      ##        SUDO TESTS         ##
      ##                           ##
      ###############################

      ## SUDO TEST1
      def can_gitolite_sudo_to_redmine_user?
        return true if gitolite_user == redmine_user
        logger.info("Testing if Gitolite user '#{gitolite_user}' can sudo to Redmine user '#{redmine_user}'...")
        result = execute_sudo_test(redmine_user) do
          RedmineGitHosting::Commands.sudo_capture('sudo', '-n', '-u', redmine_user, '-i', 'whoami')
        end
        result ? logger.info("OK!") : logger.error("Error while testing can_gitolite_sudo_to_redmine_user")
        result
      end


      ## SUDO TEST2
      def can_redmine_sudo_to_gitolite_user?
        return true if gitolite_user == redmine_user
        logger.info("Testing if Redmine user '#{redmine_user}' can sudo to Gitolite user '#{gitolite_user}'...")
        result = execute_sudo_test(gitolite_user) do
          RedmineGitHosting::Commands.sudo_capture('whoami')
        end
        result ? logger.info("OK!") : logger.error("Error while testing can_redmine_sudo_to_gitolite_user")
        result
      end


      def execute_sudo_test(user, &block)
        begin
          test = yield if block_given?
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          return false
        else
          if test.match(/#{user}/)
            return true
          else
            return false
          end
        end
      end

    end

  end
end
