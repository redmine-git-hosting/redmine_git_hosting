module RedmineGitolite

  module ConfigRedmine

    ###############################
    ##                           ##
    ##  CONFIGURATION ACCESSORS  ##
    ##                           ##
    ###############################


    def self.get_setting(setting)
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
