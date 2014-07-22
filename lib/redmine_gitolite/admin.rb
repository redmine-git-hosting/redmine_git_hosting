require 'gitolite'
require 'lockfile'

module RedmineGitolite

  class Admin

    def initialize(object_id, action, options)
      @gitolite_admin_dir                = RedmineGitolite::Config.gitolite_admin_dir
      @gitolite_config_file              = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_config_file)
      @gitolite_default_config_file      = RedmineGitolite::Config::GITOLITE_DEFAULT_CONFIG_FILE
      @gitolite_config_file_path         = File.join(@gitolite_admin_dir, 'conf', @gitolite_config_file)
      @gitolite_default_config_file_path = File.join(@gitolite_admin_dir, 'conf', @gitolite_default_config_file)
      @gitolite_identifier_prefix        = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_identifier_prefix)

      @delete_git_repositories   = RedmineGitolite::ConfigRedmine.get_setting(:delete_git_repositories, true)
      @gitolite_server_port      = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_server_port)
      @gitolite_admin_url        = RedmineGitolite::Config.gitolite_admin_url
      @gitolite_admin_ssh_script_path = RedmineGitolite::Config.gitolite_admin_ssh_script_path
      @lock_file_path = File.join(RedmineGitolite::Config.get_temp_dir_path, 'redmine_git_hosting_lock')
      @gitolite_debug = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_log_level) == 'debug' ? true : false
      @gitolite_timeout = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_timeout).to_i
      @gitolite_author  = RedmineGitolite::Config.gitolite_commit_author

      @object_id      = object_id
      @action         = action
      @options        = options
    end


    def purge_recycle_bin
      repositories_array = @object_id
      recycle = RedmineGitolite::Recycle.new
      recycle.delete_expired_files(repositories_array)
      logger.info { "#{@action} : done !" }
    end


    private


    def logger
      RedmineGitolite::Log.get_logger(:worker)
    end


    def gitolite_admin_repo_clone

      ## Get or clone Gitolite Admin repo
      if !Gitolite::GitoliteAdmin.is_gitolite_admin_repo?(@gitolite_admin_dir)
        logger.info { "Clone Gitolite Admin Repo : #{@gitolite_admin_url} (port : #{@gitolite_server_port}) to #{@gitolite_admin_dir}" }

        begin
          RedmineGitolite::GitHosting.execute_command(:local_cmd, "rm -rf '#{@gitolite_admin_dir}'")
          RedmineGitolite::GitHosting.execute_command(:local_cmd, "env GIT_SSH=#{@gitolite_admin_ssh_script_path} git clone ssh://#{@gitolite_admin_url} #{@gitolite_admin_dir}")
          RedmineGitolite::GitHosting.execute_command(:local_cmd, "chmod 700 '#{@gitolite_admin_dir}'")
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { e.command }
          logger.error { e.output }
          logger.error { "Cannot clone Gitolite Admin repository !!" }
          return false
        end
      end

      ## Set Gitolite config file
      if @gitolite_config_file != @gitolite_default_config_file
        if !File.exists?(@gitolite_config_file_path)
          begin
            RedmineGitolite::GitHosting.execute_command(:local_cmd, "touch '#{@gitolite_config_file_path}'")
          rescue RedmineGitolite::GitHosting::GitHostingException => e
            logger.error { e.message }
            logger.error { "Cannot create Gitolite configuration file '#{@gitolite_config_file_path}' !!" }
            return false
          end
        end

        begin
          include_present = RedmineGitolite::GitHosting.execute_command(:local_cmd, "grep '#{@gitolite_config_file}' #{@gitolite_default_config_file_path} | wc -l")
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { e.message }
          logger.error { "Cannot know if 'include #{@gitolite_config_file}' is present in Gitolite configuration file '#{@gitolite_default_config_file_path}' !!" }
          return false
        end

        if include_present.to_i == 1
          logger.info { "Directive 'include \"#{@gitolite_config_file}\"' is already present in Gitolite configuration file '#{@gitolite_default_config_file}'" }
        else
          logger.warn { "Directive 'include \"#{@gitolite_config_file}\"' is not present in Gitolite configuration file '#{@gitolite_default_config_file}'" }
        end

      else
        if !File.exists?(@gitolite_config_file_path)
          logger.error { "Gitolite configuration file does not exist '#{@gitolite_config_file_path}' !!" }
          logger.error { "Please check your Gitolite installation" }
          return false
        end
      end

      ## Return Gitolite::GitoliteAdmin object
      logger.info { "Using Gitolite configuration file : '#{@gitolite_config_file}'" }

      @gitolite_admin = Gitolite::GitoliteAdmin.new(@gitolite_admin_dir, :config_file => @gitolite_config_file,
                                                                         :debug       => @gitolite_debug,
                                                                         :timeout     => @gitolite_timeout,
                                                                         :env         => {'GIT_SSH' => @gitolite_admin_ssh_script_path})
      @gitolite_config = @gitolite_admin.config
    end


    def gitolite_admin_repo_commit(message = '')
      logger.info { "#{@action} : commiting to Gitolite..." }
      begin
        @gitolite_admin.save("'#{@action} : #{message}'", :author => @gitolite_author)
      rescue => e
        if !e.out.include?('nothing to commit')
          logger.error { "#{e.message}" }
        end
      end
    end


    def gitolite_admin_repo_push
      logger.info { "#{@action} : pushing to Gitolite..." }
      begin
        @gitolite_admin.apply
      rescue => e
        logger.error { "#{e.message}" }
      end
    end


    ###############################
    ##                           ##
    ##      LOCK FUNCTIONS       ##
    ##                           ##
    ###############################


    @@lock_file = nil

    def get_lock_file
      begin
        lock_file ||= File.new(@lock_file_path, File::CREAT|File::RDONLY)
      rescue Exception => e
        lock_file = nil
      end

      @@lock_file = lock_file
    end


    def get_lock
      lock_file = get_lock_file

      if !lock_file.nil? && File.exist?(lock_file)
        File.open(lock_file) do |file|
          file.sync = true
          file.flock(File::LOCK_EX)
          logger.debug { "#{@action} : get lock !" }

          yield

          file.flock(File::LOCK_UN)
          logger.debug { "#{@action} : lock released !" }
        end
      else
        logger.error { "#{@action} : cannot get lock, file does not exist #{lock_file} !" }
      end
    end


    def wrapped_transaction
      get_lock do
        gitolite_admin_repo_clone

        yield

        gitolite_admin_repo_push

        logger.info { "#{@action} : done !" }
      end
    end

  end
end
