module RedmineGitolite

  module ConfigRedmine

    ###############################
    ##                           ##
    ##  CONFIGURATION ACCESSORS  ##
    ##                           ##
    ###############################


    class << self

      def get_setting(setting, bool = false)
        if bool
          return_bool do_get_setting(setting)
        else
          return do_get_setting(setting)
        end
      end


      ### PRIVATE ###


      def return_bool(value)
        value == 'true' ? true : false
      end


      def do_get_setting(setting)
        setting = setting.to_sym

        ## Wrap this in a begin/rescue statement because Setting table
        ## may not exist on first migration
        begin
          value = Setting.plugin_redmine_git_hosting[setting]
        rescue => e
          value = Redmine::Plugin.find("redmine_git_hosting").settings[:default][setting]
        else
          ## The Setting table exist but does not contain the value yet, fallback to default
          if value.nil?
            value = Redmine::Plugin.find("redmine_git_hosting").settings[:default][setting]
          end
        end

        value
      end

    end

    private_class_method :return_bool,
                         :do_get_setting

  end
end
