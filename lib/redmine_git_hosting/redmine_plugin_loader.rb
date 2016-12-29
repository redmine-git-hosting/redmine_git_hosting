module RedmineGitHosting
  module RedminePluginLoader
    extend self

    def set_plugin_name(name)
      @name ||= name
    end


    def plugin_name
      @name
    end


    def set_autoloaded_paths(*dirs)
      @autoloaded_paths ||= dirs.map { |dir| plugin_app_dir(*dir) }
    end


    def autoloaded_paths
      @autoloaded_paths
    end


    def authors
      load_authors_file
    end


    def authors_file
      plugin_dir('AUTHORS')
    end


    def settings
      default_settings.merge(global_settings).merge(local_settings)
    end


    def global_settings
      load_setting_file(global_settings_file)
    end


    def local_settings
      load_setting_file(local_settings_file)
    end


    def default_settings
      load_setting_file(default_settings_file)
    end


    def default_settings_file
      plugin_lib_dir('default_settings.yml')
    end


    def global_settings_file
      Rails.root.join("#{plugin_name}.yml")
    end


    def local_settings_file
      plugin_dir('settings.yml')
    end


    def plugin_patches_dir
      plugin_lib_dir(plugin_name, 'patches')
    end


    def plugin_hooks_dir
      plugin_lib_dir(plugin_name, 'hooks')
    end


    def plugin_locales_dir
      plugin_conf_dir('locales', '**', '*.yml')
    end


    def required_lib_dirs
      plugin_lib_dir(plugin_name, '**', '*.rb')
    end


    def plugin_dir(*dirs)
      Rails.root.join('plugins', plugin_name, *dirs)
    end


    def plugin_app_dir(*dirs)
      plugin_dir('app', *dirs)
    end


    def plugin_conf_dir(*dirs)
      plugin_dir('config', *dirs)
    end


    def plugin_lib_dir(*dirs)
      plugin_dir('lib', *dirs)
    end


    def plugin_spec_dir(*dirs)
      plugin_dir('spec', *dirs)
    end


    def load_plugin!
      autoload_libs!
      autoload_paths!
      autoload_locales!
    end


    private


      def load_setting_file(file)
        return {} unless File.exists?(file)
        data = YAML::load(ERB.new(IO.read(file)).result) || {}
        data.symbolize_keys
      end


      def load_authors_file
        return [] unless File.exists?(authors_file)
        File.read(authors_file).split("\n").map { |a| RedmineGitHosting::PluginAuthor.new(a) }
      end


      def hook_file?(file)
        File.dirname(file) == plugin_hooks_dir.to_s
      end


      def autoload_libs!
        Dir.glob(required_lib_dirs).each do |file|
          # Exclude Redmine Views Hooks from Rails loader to avoid multiple calls to hooks on reload in dev environment.
          require_dependency file unless hook_file?(file)
        end
      end


      def autoload_paths!
        autoloaded_paths.each do |dir|
          ActiveSupport::Dependencies.autoload_paths += [dir] if Dir.exists?(dir)
        end
      end


      def autoload_locales!
        ::I18n.load_path += Dir.glob(plugin_locales_dir)
      end

  end
end
