module RedmineGitolite

  module Config

    GITOLITE_DEFAULT_CONFIG_FILE = 'gitolite.conf'
    GITOLITE_ADMIN_REPO          = 'gitolite-admin.git'
    GITOLITE_SCRIPTS_PARENT_DIR  = 'bin'


    # Full Gitolite URL
    def self.gitolite_admin_url
      return "#{get_string_setting(:gitolite_user)}@localhost/#{GITOLITE_ADMIN_REPO}"
    end


    def self.my_root_url(ssl = false)
      # Remove any path from httpServer in case they are leftover from previous installations.
      # No trailing /.
      my_root_path = Redmine::Utils::relative_url_root

      if ssl && get_setting(:https_server_domain) != ''
        server_domain = get_setting(:https_server_domain)
      else
        server_domain = get_setting(:http_server_domain)
      end

      my_root_url = File.join(server_domain[/^[^\/]*/], my_root_path, "/")[0..-2]

      return my_root_url
    end


    def self.gitolite_hooks_url
      if get_setting(:https_server_domain) != '' && get_setting(:https_server_domain).split(':')[0] != 'localhost'
        scheme = "https://"
        server_domain = my_root_url(true)
      else
        scheme = "http://"
        server_domain = my_root_url(false)
      end

      return File.join(scheme, server_domain, "/githooks/post-receive")
    end


    def self.get_setting(setting, bool = false)
      if bool
        return get_boolean_setting(setting)
      else
        return get_string_setting(setting)
      end
    end


    def self.get_boolean_setting(setting)
      setting = setting.to_sym
      begin
        if Setting.plugin_redmine_git_hosting[setting] == 'true'
          value = true
        else
          value = false
        end
      rescue => e
        # puts e.message
        value = Redmine::Plugin.find("redmine_git_hosting").settings[:default][setting]
      end

      if value.nil?
        value = Redmine::Plugin.find("redmine_git_hosting").settings[:default][setting]
      end

      # puts "#{setting} : '#{value}' : #{value.class.name}"

      return value
    end


    def self.get_string_setting(setting)
      setting = setting.to_sym
      begin
        value = Setting.plugin_redmine_git_hosting[setting]
      rescue => e
        # puts e.message
        value = Redmine::Plugin.find("redmine_git_hosting").settings[:default][setting]
      end

      if value.nil?
        value = Redmine::Plugin.find("redmine_git_hosting").settings[:default][setting]
      end

      # puts "#{setting} : '#{value}' : #{value.class.name}"

      return value
    end

  end
end
