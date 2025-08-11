# -*- encoding: utf-8 -*-
# stub: sidekiq 6.0.4 ruby lib

Gem::Specification.new do |s|
  s.name = "sidekiq".freeze
  s.version = "6.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mike Perham".freeze]
  s.date = "2019-12-20"
  s.description = "Simple, efficient background processing for Ruby.".freeze
  s.email = ["mperham@gmail.com".freeze]
  s.executables = ["sidekiq".freeze, "sidekiqmon".freeze]
  s.files = ["bin/sidekiq".freeze, "bin/sidekiqmon".freeze]
  s.homepage = "http://sidekiq.org".freeze
  s.licenses = ["LGPL-3.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Simple, efficient background processing for Ruby".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<redis>.freeze, [">= 4.1.0"])
  s.add_runtime_dependency(%q<connection_pool>.freeze, [">= 2.2.2"])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 2.0.0"])
  s.add_runtime_dependency(%q<rack-protection>.freeze, [">= 2.0.0"])
end
