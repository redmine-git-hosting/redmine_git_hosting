module RedmineGitHosting::GitoliteParams

  class GlobalParams

    include BaseParam

    attr_reader :gitolite_hooks_url
    attr_reader :debug_mode
    attr_reader :async_mode

    attr_reader :namespace
    attr_reader :current_params


    def initialize
      # Params to set
      @gitolite_hooks_url = RedmineGitHosting::Config.gitolite_hooks_url
      @debug_mode         = RedmineGitHosting::Config.gitolite_hooks_debug.to_s
      @async_mode         = RedmineGitHosting::Config.gitolite_hooks_are_asynchronous.to_s

      # Namespace where to set params
      @namespace = RedmineGitHosting::Config.gitolite_hooks_namespace

      # Get current params
      @current_params = get_git_config_params(@namespace)

      # Build hash of installed params
      @installed = {}
    end


    def installed?
      gitolite_hooks_url_set?
      debug_mode_set?
      async_mode_set?
      @installed
    end


    private


      def gitolite_hooks_url_set?
        if current_params['redmineurl'] != gitolite_hooks_url
          @installed['redmineurl'] = set_git_config_param(namespace, 'redmineurl', gitolite_hooks_url)
        else
          @installed['redmineurl'] = true
        end
      end


      def debug_mode_set?
        if current_params['debugmode'] != debug_mode
          @installed['debugmode'] = set_git_config_param(namespace, 'debugmode', debug_mode)
        else
          @installed['debugmode'] = true
        end
      end


      def async_mode_set?
        if current_params['asyncmode'] != async_mode
          @installed['asyncmode'] = set_git_config_param(namespace, 'asyncmode', async_mode)
        else
          @installed['asyncmode'] = true
        end
      end

  end
end
