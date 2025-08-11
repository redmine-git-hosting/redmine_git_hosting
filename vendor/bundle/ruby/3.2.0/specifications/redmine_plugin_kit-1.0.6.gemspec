# -*- encoding: utf-8 -*-
# stub: redmine_plugin_kit 1.0.6 ruby lib

Gem::Specification.new do |s|
  s.name = "redmine_plugin_kit".freeze
  s.version = "1.0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["AlphaNodes".freeze]
  s.date = "2024-11-10"
  s.description = "Redmine plugin kit as base of Redmine plugins".freeze
  s.email = ["alex@alphanodes.com".freeze]
  s.homepage = "https://github.com/alphanodes/redmine_plugin_kit".freeze
  s.licenses = ["GPL-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Redmine plugin kit".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<deface>.freeze, ["= 1.9.0"])
  s.add_runtime_dependency(%q<rails>.freeze, [">= 0"])
end
