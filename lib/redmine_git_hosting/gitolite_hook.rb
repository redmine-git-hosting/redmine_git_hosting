module RedmineGitHosting
  class GitoliteHook

    class << self

      def def_field(*names)
        class_eval do
          names.each do |name|
            define_method(name) do |*args|
              args.empty? ? instance_variable_get("@#{name}") : instance_variable_set("@#{name}", *args)
            end
          end
        end
      end

    end

    def_field :name, :source, :destination, :executable

    attr_reader :source_dir


    def initialize(source_dir, &block)
      @source_dir = source_dir
      instance_eval(&block)
    end


    def source_path
      File.join(source_dir, source)
    end


    def destination_path
      File.join(gitolite_hooks_dir, destination)
    end


    def parent_path
      dirname = File.dirname(destination)
      dirname = '' if dirname == '.'
      File.join(gitolite_hooks_dir, dirname)
    end


    def filemode
      executable ? '755' : '644'
    end


    def installed?
      if !file_exists?
        1
      elsif hook_file_has_changed?
        2
      else
        0
      end
    end


    def install!
      if !file_exists?
        logger.info("Hook '#{name}' does not exist, installing it ...")
        install_hook
      elsif hook_file_has_changed?
        logger.warn("Hook '#{name}' is already present but it's not ours!")
        if force_update?
          logger.info("Restoring '#{name}' hook since forceInstallHook == true")
          install_hook
        else
          logger.info("Leaving '#{name}' hook untouched since forceInstallHook == false")
        end
      else
        logger.info("Hook '#{name}' is correcly installed")
      end
      installed?
    end


    private


      def install_hook
        create_parent_dir if !directory_exists?
        if install_hook_file
          logger.info("Hook '#{name}' installed")
          update_gitolite
        end
      end


      def force_update?
        RedmineGitHosting::Config.gitolite_overwrite_existing_hooks?
      end


      def logger
        RedmineGitHosting.logger
      end


      def hook_file_has_changed?
        RedmineGitHosting::Commands.sudo_file_changed?(source_path, destination_path) ||
          RedmineGitHosting::Commands.sudo_file_perms_changed?(filemode, destination_path)
      end


      def file_exists?
        RedmineGitHosting::Commands.sudo_file_exists?(destination_path)
      end


      def install_hook_file
        logger.info("Installing hook '#{source_path}' in '#{destination_path}'")
        begin
          content = File.read(source_path)
        rescue Errno::ENOENT => e
          logger.error("Errors while installing hook '#{e.message}'")
          return false
        else
          RedmineGitHosting::Commands.sudo_install_file(content, destination_path, filemode)
        end
      end


      def update_gitolite
        RedmineGitHosting::Commands.sudo_update_gitolite!
      end


      def gitolite_hooks_dir
        RedmineGitHosting::Config.gitolite_hooks_dir
      end


      def directory_exists?
        RedmineGitHosting::Commands.sudo_dir_exists?(parent_path)
      end


      def create_parent_dir
        logger.info("Installing hook directory '#{parent_path}'")

        begin
          RedmineGitHosting::Commands.sudo_mkdir_p(parent_path)
          return true
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Problems installing hook directory '#{parent_path}'")
          logger.error(e.output)
          return false
        end
      end

  end
end
