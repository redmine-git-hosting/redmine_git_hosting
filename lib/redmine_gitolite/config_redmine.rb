module RedmineGitolite

  module ConfigRedmine

    ###############################
    ##                           ##
    ##  CONFIGURATION ACCESSORS  ##
    ##                           ##
    ###############################


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
