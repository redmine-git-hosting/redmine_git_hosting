require 'digest/md5'

module RedmineGitolite::HookManager

  class HookFile

    attr_reader :name
    attr_reader :source_path
    attr_reader :destination_path
    attr_reader :filemode


    def initialize(name, source_path, destination_path, executable)
      @name             = name
      @source_path      = source_path
      @destination_path = destination_path
      @filemode         = executable ? '755' : '644'
      @force_update     = RedmineGitolite::Config.get_setting(:gitolite_force_hooks_update, true)
    end


    def installed?
      if !exists?
        logger.info { "Hook '#{name}' does not exist, installing it ..." }
        do_install_file
      elsif hook_are_different?
        logger.warn { "Hook '#{name}' is already present but it's not ours!" }

        if @force_update
          logger.info { "Restoring '#{name}' hook since forceInstallHook == true" }
          do_install_file
        end
      end
      return exists?
    end


    private


      def do_install_file
        if install_hook_file
          logger.info { "Hook '#{name}' installed" }
          logger.info { "Running '#{gitolite_command}' on the Gitolite install ..." }
          update_gitolite
        end
      end


      def logger
        RedmineGitolite::Log.get_logger(:global)
      end


      def hook_are_different?
        local_md5 != distant_md5
      end


      def local_md5
        Digest::MD5.hexdigest(File.read(source_path))
      end


      def distant_md5
        content = RedmineGitolite::GitoliteWrapper.sudo_capture('eval', 'cat', destination_path) rescue ''
        Digest::MD5.hexdigest(content)
      end


      def gitolite_command
        RedmineGitolite::GitoliteWrapper.gitolite_command
      end


      def exists?
        begin
          RedmineGitolite::GitoliteWrapper.sudo_file_exists?(destination_path)
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          return false
        end
      end


      def install_hook_file
        logger.info { "Installing hook '#{source_path}' in '#{destination_path}'" }

        begin
          RedmineGitolite::GitoliteWrapper.sudo_pipe("sh") do
            [ 'cat', '<<\EOF', '>' + destination_path, "\n" + File.read(source_path) + "EOF" ].join(' ')
          end
          RedmineGitolite::GitoliteWrapper.sudo_chmod(filemode, destination_path)
          return true
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Problems installing hook from '#{source_path}' in '#{destination_path}'" }
          logger.error { e.output }
          return false
        end
      end


      def update_gitolite
        begin
          RedmineGitolite::GitoliteWrapper.sudo_shell(*gitolite_command)
          return true
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          return false
        end
      end

  end
end
