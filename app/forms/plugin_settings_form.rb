class PluginSettingsForm
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
    Hash[self.class.all_accessors.map { |v| [v, send(v)] }]
  end

  private

  def current_setting(setting)
    Setting.plugin_redmine_git_hosting[setting]
  end

  def strip_value(value)
    return '' if value.nil?

    value.strip
  end

  def filter_email_list(list)
    list.select(&:present?).select { |m| valid_email?(m) }
  end

  def valid_email?(email)
    RedmineGitHosting::Validators.valid_email?(email)
  end

  def convert_time(time)
    (time.to_f * 10).to_i / 10.0
  end
end
