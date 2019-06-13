module RedmineGitHosting
  module Config
    module Base
      extend self

      ###############################
      ##                           ##
      ##  CONFIGURATION ACCESSORS  ##
      ##                           ##
      ###############################

      def get_setting(setting, bool = false)
        if bool
          Additionals.true? do_get_setting(setting)
        else
          do_get_setting(setting)
        end
      end

      def reload_from_file!
        ## Get default config from init.rb
        default_hash = Redmine::Plugin.find('redmine_git_hosting').settings[:default]
        do_reload_config(default_hash)
      end

      def dump_settings
        puts YAML.dump Redmine::Plugin.find('redmine_git_hosting').settings[:default]
      end

      private

      def do_get_setting(setting)
        setting = setting.to_sym

        ## Wrap this in a begin/rescue statement because Setting table
        ## may not exist on first migration
        begin
          value = Setting.plugin_redmine_git_hosting[setting]
        rescue
          value = Redmine::Plugin.find('redmine_git_hosting').settings[:default][setting]
        else
          ## The Setting table exist but does not contain the value yet, fallback to default
          value = Redmine::Plugin.find('redmine_git_hosting').settings[:default][setting] if value.nil?
        end

        value
      end

      def do_reload_config(default_hash)
        ## Refresh Settings cache
        Setting.check_cache

        ## Get actual values
        valuehash = (Setting.plugin_redmine_git_hosting).clone rescue {}

        ## Update!
        changes = 0

        default_hash.each do |key, value|
          if valuehash[key] != value
            console_logger.info("Changing '#{key}' : #{valuehash[key]} => #{value}")
            valuehash[key] = value
            changes += 1
          end
        end

        if changes.zero?
          console_logger.info('No changes necessary.')
        else
          commit_changes(valuehash)
        end
      end

      def commit_changes(valuehash)
        console_logger.info('Committing changes ... ')
        begin
          ## Update Settings
          Setting.plugin_redmine_git_hosting = valuehash
          ## Refresh Settings cache
          Setting.check_cache
          console_logger.info('Success!')
        rescue => e
          console_logger.error('Failure.')
          console_logger.error(e.message)
        end
      end

      def console_logger
        RedmineGitHosting::ConsoleLogger
      end

      def file_logger
        RedmineGitHosting.logger
      end
    end
  end
end
