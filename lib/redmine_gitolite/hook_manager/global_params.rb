module RedmineGitolite::HookManager

  class GlobalParams < HookParam

    attr_reader :gitolite_hooks_url
    attr_reader :debug_mode
    attr_reader :async_mode

    attr_reader :namespace
    attr_reader :current_params


    def initialize
      ## Params to set
      @gitolite_hooks_url = RedmineGitolite::GitoliteWrapper.gitolite_hooks_url
      @debug_mode         = RedmineGitolite::Config.get_setting(:gitolite_hooks_debug, true).to_s
      @async_mode         = RedmineGitolite::Config.get_setting(:gitolite_hooks_are_asynchronous, true).to_s

      ## Namespace where to set params
      @namespace = RedmineGitolite::HookManager.gitolite_hooks_namespace

      ## Get current params
      @current_params = get_git_config_params(@namespace)
    end


    def installed?
      installed = {}

      if current_params["redmineurl"] != gitolite_hooks_url
        installed['redmineurl'] = set_git_config_param(namespace, "redmineurl", gitolite_hooks_url)
      else
        installed['redmineurl'] = true
      end

      if current_params["debugmode"] != debug_mode
        installed['debugmode'] = set_git_config_param(namespace, "debugmode", debug_mode)
      else
        installed['debugmode'] = true
      end

      if current_params["asyncmode"] != async_mode
        installed['asyncmode'] = set_git_config_param(namespace, "asyncmode", async_mode)
      else
        installed['asyncmode'] = true
      end

      return installed
    end

  end
end
