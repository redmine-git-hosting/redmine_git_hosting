# frozen_string_literal: true

module RedminePluginKit
  class Engine < Rails::Engine
    config.paths.add 'app/overrides', eager_load: true
  end
end
