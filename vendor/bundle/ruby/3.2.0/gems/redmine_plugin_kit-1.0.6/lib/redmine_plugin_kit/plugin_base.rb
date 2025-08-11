# frozen_string_literal: true

module RedminePluginKit
  module PluginBase
    def self.included(receiver)
      receiver.extend ClassMethods
    end

    module ClassMethods
      def setup!(existing_loader = nil)
        init_loader existing_loader
        raise "no loader for #{plugin_id}" if loader.nil?

        setup_required_plugins
        setup
      end

      def plugin_id
        to_s.underscore
      end

      def loader
        @loader ||= RedminePluginKit::Loader.new plugin_id: plugin_id
      end

      # support with default setting as fall back
      def setting(value)
        if settings.key? value
          settings[value]
        else
          loader.default_settings[value]
        end
      end

      def setting?(value)
        RedminePluginKit.true? setting(value)
      end

      private

      # rubocop: disable Style/RaiseArgs
      def setup_required_plugins
        return unless defined? self::REQUIRED_ALPHANODES_PLUGINS
        raise 'VERSION missing for REQUIRED_ALPHANODES_PLUGINS' unless defined? self::VERSION

        self::REQUIRED_ALPHANODES_PLUGINS.each do |required_plugin|
          plugin = Redmine::Plugin.find required_plugin
          unless self::VERSION.include? plugin.version
            raise Redmine::PluginRequirementError.new "#{plugin_id} plugin requires #{required_plugin} plugin version #{self::VERSION}"
          end
        rescue Redmine::PluginNotFound
          raise Redmine::PluginRequirementError.new "#{plugin_id} plugin requires the #{required_plugin} plugin." \
                                              "Please install #{required_plugin} plugin (https://alphanodes.com/#{required_plugin.tr '-',
                                                                                                                                     '_'})"
        end
      end
      # rubocop: enable Style/RaiseArgs

      def init_loader(existing_loader)
        @loader = existing_loader
      end

      def settings
        Setting[:"plugin_#{plugin_id}"]
      end
    end
  end
end
