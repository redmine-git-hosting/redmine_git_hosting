require 'gitolite'
require 'lockfile'

module RedmineGitolite

  class Admin

    include RedmineGitolite::AdminHelper

    def initialize(object_id, action)
      @gitolite_admin_dir        = RedmineGitolite::Config.gitolite_admin_dir
      @gitolite_config_file      = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_config_file)
      @gitolite_config_file_path = File.join(@gitolite_admin_dir, 'conf', @gitolite_config_file)
      @delete_git_repositories   = RedmineGitolite::ConfigRedmine.get_setting(:delete_git_repositories, true)
      @gitolite_server_port      = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_server_port)
      @gitolite_admin_url        = RedmineGitolite::Config.gitolite_admin_url
      @gitolite_admin_ssh_script_path = RedmineGitolite::Config.gitolite_admin_ssh_script_path
      @lock_file_path = File.join(RedmineGitolite::Config.get_temp_dir_path, 'redmine_git_hosting_lock')
      @object_id      = object_id
      @action         = action
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
      if (File.exists? "#{@gitolite_admin_dir}") && (File.exists? "#{@gitolite_admin_dir}/.git") && (File.exists? "#{@gitolite_admin_dir}/keydir") && (File.exists? "#{@gitolite_admin_dir}/conf")
        @gitolite_admin = Gitolite::GitoliteAdmin.new(@gitolite_admin_dir)
      else
        begin
          logger.info { "Clone Gitolite Admin Repo : #{@gitolite_admin_url} (port : #{@gitolite_server_port}) to #{@gitolite_admin_dir}" }

          RedmineGitolite::GitHosting.shell %[rm -rf "#{@gitolite_admin_dir}"]
          RedmineGitolite::GitHosting.shell %[env GIT_SSH=#{@gitolite_admin_ssh_script_path} git clone ssh://#{@gitolite_admin_url} #{@gitolite_admin_dir}]
          RedmineGitolite::GitHosting.shell %[chmod 700 "#{@gitolite_admin_dir}"]

          @gitolite_admin = Gitolite::GitoliteAdmin.new(@gitolite_admin_dir)
        rescue => e
          logger.error { e.message }
          logger.error { "Cannot clone Gitolite Admin repository !!" }
          return false
        end
      end

      if @gitolite_config_file != RedmineGitolite::Config::GITOLITE_DEFAULT_CONFIG_FILE
        if !File.exists?(@gitolite_config_file_path)
          begin
            RedmineGitolite::GitHosting.shell %[touch "#{@gitolite_config_file_path}"]
          rescue => e
            logger.error { e.message }
            logger.error { "Cannot create Gitolite configuration file '#{@gitolite_config_file_path}' !!" }
            return false
          end
        end
      else
        if !File.exists?(@gitolite_config_file_path)
          logger.error { "Gitolite configuration file does not exist '#{@gitolite_config_file_path}' !!" }
          logger.error { "Please check your Gitolite installation" }
          return false
        end
      end

      logger.info { "Using Gitolite configuration file : '#{@gitolite_config_file}'" }
      @gitolite_admin.config = @gitolite_config = Gitolite::Config.new(@gitolite_config_file_path)
    end


    def gitolite_admin_repo_commit(message = nil)
      @gitolite_admin.save("#{@action} : #{message}")
    end


    def gitolite_admin_repo_push
      logger.info { "#{@action} : pushing to Gitolite..." }
      begin
        @gitolite_admin.apply
      rescue => e
        logger.error { "Error : #{e.message}" }
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
