class PluginSettingsForm
  unloadable

  DOMAIN_REGEX   = /\A[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*(:\d+)?\z/i
  EMAIL_REGEX    = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  BOOLEAN_FIELDS = ['true', 'false']
  CACHE_ADAPTERS = ['database', 'memcached', 'redis']
  LOG_LEVELS     = ['debug', 'info', 'warn', 'error']

  class << self

    def add_accessor(*args)
      @accessors ||= []
      args.each do |accessor|
        @accessors << accessor
        attr_accessor accessor
      end
    end


    def all_accessors
      @accessors
    end

  end

  include BaseForm
  include PluginSettingsValidation::CacheConfig
  include PluginSettingsValidation::GitoliteAccessConfig
  include PluginSettingsValidation::GitoliteConfig
  include PluginSettingsValidation::HooksConfig
  include PluginSettingsValidation::MailingListConfig
  include PluginSettingsValidation::RedmineConfig
  include PluginSettingsValidation::SshConfig
  include PluginSettingsValidation::StorageConfig


  attr_reader :plugin


  def initialize(plugin)
    @plugin = plugin
  end


  def params
    Hash[self.class.all_accessors.map { |v|
      [v, self.send(v)]
    }]
  end


  private


    def current_setting(setting)
      Setting.plugin_redmine_git_hosting[setting]
    end


    def strip_value(value)
      return '' if value.nil?
      value.lstrip.rstrip
    end


    def filter_email_list(list)
      list.select{ |m| !m.blank? }.select{ |m| valid_email?(m) }
    end


    def valid_email?(email)
      email.match(EMAIL_REGEX)
    end


    def convert_time(time)
      (time.to_f * 10).to_i / 10.0
    end

end
