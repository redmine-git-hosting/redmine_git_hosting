module RedmineGitolite

  class HookParam


    def initialize
      @gitolite_hooks_url = RedmineGitolite::Config.gitolite_hooks_url
      @debug_mode         = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_hooks_debug, true)
      @async_mode         = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_hooks_are_asynchronous, true)
      @gitolite_namespace = RedmineGitolite::HookManager.gitolite_hooks_namespace
      @global_hook_params = get_global_hooks_params
    end


    def installed?
      installed = {}

      if @global_hook_params["redmineurl"] != @gitolite_hooks_url
        installed['redmineurl'] = set_hook_param("redmineurl", @gitolite_hooks_url)
      else
        installed['redmineurl'] = true
      end

      if @global_hook_params["debugmode"] != @debug_mode.to_s
        installed['debugmode'] = set_hook_param("debugmode", @debug_mode)
      else
        installed['debugmode'] = true
      end

      if @global_hook_params["asyncmode"] != @async_mode.to_s
        installed['asyncmode'] = set_hook_param("asyncmode", @async_mode)
      else
        installed['asyncmode'] = true
      end

      return installed
    end


    private


      def logger
        RedmineGitolite::Log.get_logger(:global)
      end


      # Return a hash with global config parameters.
      def get_global_hooks_params
        begin
          hooks_params = RedmineGitolite::GitHosting.execute_command(:git_cmd, "config -f .gitconfig --get-regexp #{@gitolite_namespace}").split("\n")
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Problems to retrieve Gitolite hook parameters in Gitolite config" }
          hooks_params = []
        end

        value_hash = {}

        hooks_params.each do |value_pair|
          global_key = value_pair.split(' ')[0]
          namespace  = global_key.split('.')[0]
          key        = global_key.split('.')[1]
          value      = value_pair.split(' ')[1]

          if namespace == @gitolite_namespace
            value_hash[key] = value
          end
        end

        return value_hash
      end


      def set_hook_param(name, value)
        logger.info { "Set Git hooks global parameter : #{name} (#{value})" }

        begin
          RedmineGitolite::GitHosting.execute_command(:git_cmd, "config --global #{@gitolite_namespace}.#{name} '#{value}'")
          return true
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Error while setting Git hooks global parameter : #{name} (#{value})" }
          return false
        end

      end

  end
end
