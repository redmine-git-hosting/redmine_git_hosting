# -*- encoding: utf-8 -*-
# stub: factory_bot_rails 4.11.1 ruby lib

Gem::Specification.new do |s|
  s.name = "factory_bot_rails".freeze
  s.version = "4.11.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Joe Ferris".freeze]
  s.date = "2018-09-07"
  s.description = "factory_bot_rails provides integration between\n    factory_bot and rails 3 or newer (currently just automatic factory definition\n    loading)".freeze
  s.email = "jferris@thoughtbot.com".freeze
  s.homepage = "https://github.com/thoughtbot/factory_bot_rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "factory_bot_rails provides integration between factory_bot and rails 3 or newer".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 3.0.0"])
  s.add_runtime_dependency(%q<factory_bot>.freeze, ["~> 4.11.1"])
end
