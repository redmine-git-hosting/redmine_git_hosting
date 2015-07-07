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


    def plugin_patches_dir
      plugin_lib_dir(plugin_name, 'patches')
    end


    def plugin_hooks_dir
      plugin_lib_dir(plugin_name, 'hooks')
    end


    def required_lib_dirs
      plugin_lib_dir(plugin_name, '**', '*.rb')
    end


    def load_plugin!
      autoload_libs!
      autoload_paths!
      autoload_locales!
    end


    def autoload_libs!
      Dir.glob(required_lib_dirs).each do |file|
        # Exclude Redmine Views Hooks from Rails loader to avoid multiple calls to hooks on reload in dev environment.
        require_dependency file unless File.dirname(file) == plugin_hooks_dir.to_s
      end
    end


    def autoload_paths!
      autoloaded_paths.each do |dir|
        ActiveSupport::Dependencies.autoload_paths += [dir] if Dir.exists?(dir)
      end
    end


    def autoload_locales!
      ::I18n.load_path += Dir.glob(plugin_conf_dir('locales', '**', '*.yml'))
    end

  end
end
