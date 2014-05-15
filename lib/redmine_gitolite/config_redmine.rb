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


    def self.reload_config(config = nil)
      if !config.nil?
        default_hash = config
      else
        default_hash = Redmine::Plugin.find("redmine_git_hosting").settings[:default]
      end

      if default_hash.nil? || default_hash.empty?
        RedmineGitolite::GitHosting.logger.info { "No defaults specified in init.rb!" }
      else
        changes = 0
        valuehash = (Setting.plugin_redmine_git_hosting).clone rescue {}
        default_hash.each do |key, value|
          if valuehash[key] != value
            RedmineGitolite::GitHosting.logger.info { "Changing '#{key}' : #{valuehash[key]} => #{value}" }
            changes += 1
          end

          if value.is_a?(String) || value.is_a?(TrueClass) || value.is_a?(FalseClass)
            valuehash[key] = value.to_s
          else
            valuehash[key] = value
          end
        end

        if changes == 0
          RedmineGitolite::GitHosting.logger.info { "No changes necessary." }
        else
          RedmineGitolite::GitHosting.logger.info { "Committing changes ... " }
          begin
            Setting.plugin_redmine_git_hosting = valuehash
            RedmineGitolite::GitHosting.logger.info { "Success!" }
          rescue => e
            RedmineGitolite::GitHosting.logger.error { "Failure." }
            RedmineGitolite::GitHosting.logger.error { e.message }
          end
        end
      end
    end

  end

end
