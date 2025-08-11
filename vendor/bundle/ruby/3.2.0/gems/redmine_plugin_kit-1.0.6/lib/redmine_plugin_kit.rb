# frozen_string_literal: true

require 'deface'

require 'redmine_plugin_kit/version'
require 'redmine_plugin_kit/debug'
require 'redmine_plugin_kit/engine'
require 'redmine_plugin_kit/plugin_base'
require 'redmine_plugin_kit/loader'

require 'redmine_plugin_kit/helpers/global_helper'

ActiveSupport.on_load(:action_view) { include RedminePluginKit::Helpers::GlobalHelper } if defined?(ActionView::Base)

module RedminePluginKit
  class << self
    def true?(value)
      return false if value.is_a? FalseClass
      return true if value.is_a?(TrueClass) || value.to_i == 1 || value.to_s.casecmp('true').zero?

      false
    end

    # false if false or nil
    def false?(value)
      !true?(value)
    end

    def textarea_cols(text, min: 8, max: 20)
      [[min, text.to_s.length / 50].max, max].min # rubocop: disable Style/ComparableClamp
    end
  end
end
