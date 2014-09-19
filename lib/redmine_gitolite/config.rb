module RedmineGitolite

  module Config

    GITHUB_ISSUE = 'https://github.com/jbox-web/redmine_git_hosting/issues'
    GITHUB_WIKI  = 'https://github.com/jbox-web/redmine_git_hosting/wiki/Configuration-variables'

    GITOLITE_DEFAULT_CONFIG_FILE       = 'gitolite.conf'
    GITOLITE_IDENTIFIER_DEFAULT_PREFIX = 'redmine_'


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


      def reload_from_file!(opts = {})
        reload!(nil, opts)
      end


      ### PRIVATE ###


      def return_bool(value)
        value == 'true' ? true : false
      end


      def do_get_setting(setting)
        setting = setting.to_sym

        if Setting.plugin_redmine_git_hosting.nil?
          value = Redmine::Plugin.find("redmine_git_hosting").settings[:default][setting]
        else
          value = Setting.plugin_redmine_git_hosting[setting]
          if value.nil?
            value = Redmine::Plugin.find("redmine_git_hosting").settings[:default][setting]
          end
        end

        value
      end


      def reload!(config = nil, opts = {})
        logger = ConsoleLogger.new(opts)

        if !config.nil?
          default_hash = config
        else
          ## Get default config from init.rb
          default_hash = Redmine::Plugin.find("redmine_git_hosting").settings[:default]
        end

        if default_hash.nil? || default_hash.empty?
          logger.info { "No defaults specified in init.rb!" }
        else
          ## Refresh Settings cache
          Setting.check_cache

          ## Get actual values
          valuehash = (Setting.plugin_redmine_git_hosting).clone

          ## Update!
          changes = 0

          default_hash.each do |key, value|
            if valuehash[key] != value
              logger.info { "Changing '#{key}' : #{valuehash[key]} => #{value}" }
              valuehash[key] = value
              changes += 1
            end
          end

          if changes == 0
            logger.info { "No changes necessary." }
          else
            logger.info { "Committing changes ... " }
            begin
              ## Update Settings
              Setting.plugin_redmine_git_hosting = valuehash
              ## Refresh Settings cache
              Setting.check_cache
              logger.info { "Success!" }
            rescue => e
              logger.error { "Failure." }
              logger.error { e.message }
            end
          end
        end
      end

    end

    private_class_method :return_bool,
                         :do_get_setting,
                         :reload!


    class ConsoleLogger

      attr_reader :console

      def initialize(opts = {})
        @console = opts[:console] || false
        @logger ||= RedmineGitolite::GitHosting.logger
      end

      def info(&block)
        puts yield if console
        @logger.info yield
      end

      def error(&block)
        puts yield if console
        @logger.error yield
      end

      # Handle everything else with base object
      def method_missing(m, *args, &block)
        @logger.send m, *args, &block
      end

    end

  end
end
