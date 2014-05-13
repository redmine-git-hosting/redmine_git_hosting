module RedmineGitolite

  module GitHosting


    def self.logger
      RedmineGitolite::Log.get_logger(:global)
    end


    # Used to register errors when pulling and pushing the conf file
    class GitHostingException < StandardError
      attr_reader :command
      attr_reader :output

      def initialize(command, output)
        @command = command
        @output  = output
      end
    end


    ###############################
    ##                           ##
    ##       SHELL WRAPPERS      ##
    ##                           ##
    ###############################


    def self.resync_gitolite(data_hash)
      if data_hash.has_key?(:options)
        if data_hash[:options].has_key?(:flush_cache) && data_hash[:options][:flush_cache] == true
          logger.info { "Flush Settings Cache !" }
          Setting.check_cache
        end
      else
        data_hash[:options] = {}
      end

      if RedmineGitolite::ConfigRedmine.get_setting(:gitolite_use_sidekiq)
        GithostingShellWorker.perform_async(data_hash)
      else
        githosting_shell = RedmineGitolite::Shell.new(data_hash[:command], data_hash[:object], data_hash[:options])
        githosting_shell.handle_command
      end
    end


    def self.execute_command(command_type, command, flags = {})
      case command_type
        when :git_cmd then
          runner = RedmineGitolite::Config.git_cmd_script_path
        when :shell_cmd then
          runner = RedmineGitolite::Config.shell_cmd_script_path
        when :ssh_cmd then
          runner = RedmineGitolite::Config.gitolite_admin_ssh_script_path
        when :local_cmd then
          runner = ''
      end

      if flags.has_key?(:pipe_data)
        run_command = "#{flags[:pipe_command]} '#{flags[:pipe_data]}' | #{runner} #{command} 2>&1"
      else
        run_command = "#{runner} #{command} 2>&1"
      end

      logger.debug { run_command }

      return shell(run_command)
    end


    def self.shell(command)
      begin
        result = %x[ #{command} ]
        code = $?.exitstatus
      rescue Exception => e
        result = e.message
        code = -1
      end

      if code != 0
        command = "Command failed (return #{code}): #{command}"
        output =  "Command output : '#{result.split("\n").join("\n  ")}'"
        raise GitHostingException.new(command, output), "Shell Error"
      end

      return result
    end


    ## TEST IF FILE EXIST ON GITOLITE SIDE
    def self.file_exists?(filename)
      begin
        exists = execute_command(:shell_cmd, "test -r '#{filename}' && echo 'yes' || echo 'no'").match(/yes/) ? true : false
      rescue GitHostingException => e
        exists = false
      end
      return exists
    end


    ## TEST IF DIRECTORY EXIST ON GITOLITE SIDE
    def self.dir_exists?(dirname)
      begin
        exists = execute_command(:shell_cmd, "test -d '#{dirname}' && echo 'yes' || echo 'no'").match(/yes/) ? true : false
      rescue GitHostingException => e
        exists = false
      end
      return exists
    end

  end
end
