module RedmineGitolite

  module Config

    ###############################
    ##                           ##
    ##  CONFIGURATION ACCESSORS  ##
    ##                           ##
    ###############################


    GITHUB_ISSUE = 'https://github.com/jbox-web/redmine_git_hosting/issues'
    GITHUB_WIKI  = 'https://github.com/jbox-web/redmine_git_hosting/wiki/Configuration-variables'

    GITOLITE_DEFAULT_CONFIG_FILE       = 'gitolite.conf'
    GITOLITE_IDENTIFIER_DEFAULT_PREFIX = 'redmine_'


    def self.logger
      RedmineGitolite::GitHosting.logger
    end


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


    def self.reload!(config = nil)
      if !config.nil?
        default_hash = config
      else
        default_hash = Redmine::Plugin.find("redmine_git_hosting").settings[:default]
      end

      if default_hash.nil? || default_hash.empty?
        logger.info { "No defaults specified in init.rb!" }
      else
        changes = 0
        valuehash = (Setting.plugin_redmine_git_hosting).clone rescue {}
        default_hash.each do |key, value|
          if valuehash[key] != value
            logger.info { "Changing '#{key}' : #{valuehash[key]} => #{value}" }
            changes += 1
          end

          if value.is_a?(String) || value.is_a?(TrueClass) || value.is_a?(FalseClass)
            valuehash[key] = value.to_s
          else
            valuehash[key] = value
          end
        end

        if changes == 0
          logger.info { "No changes necessary." }
        else
          logger.info { "Committing changes ... " }
          begin
            Setting.plugin_redmine_git_hosting = valuehash
            logger.info { "Success!" }
          rescue => e
            logger.error { "Failure." }
            logger.error { e.message }
          end
        end
      end
    end

  end
end
