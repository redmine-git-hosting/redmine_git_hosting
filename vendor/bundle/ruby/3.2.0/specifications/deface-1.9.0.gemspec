# -*- encoding: utf-8 -*-
# stub: deface 1.9.0 ruby lib

Gem::Specification.new do |s|
  s.name = "deface".freeze
  s.version = "1.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/spree/deface/releases", "homepage_uri" => "https://github.com/spree/deface#readme", "source_code_uri" => "https://github.com/spree/deface" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brian D Quinn".freeze]
  s.bindir = "exe".freeze
  s.date = "2022-04-01"
  s.description = "Deface is a library that allows you to customize ERB, Haml and Slim views in a Rails application without editing the underlying view.".freeze
  s.email = "brian@spreecommerce.com".freeze
  s.extra_rdoc_files = ["README.markdown".freeze]
  s.files = ["README.markdown".freeze]
  s.homepage = "https://github.com/spree/deface#readme".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Deface is a library that allows you to customize ERB, Haml and Slim views in Rails".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.6"])
  s.add_runtime_dependency(%q<actionview>.freeze, [">= 5.2"])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 5.2"])
  s.add_runtime_dependency(%q<rainbow>.freeze, [">= 2.1.0"])
  s.add_runtime_dependency(%q<polyglot>.freeze, [">= 0"])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
  s.add_development_dependency(%q<erubis>.freeze, [">= 0"])
  s.add_development_dependency(%q<gem-release>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.1.0"])
  s.add_development_dependency(%q<haml>.freeze, [">= 4.0", "< 6"])
  s.add_development_dependency(%q<slim>.freeze, ["~> 4.1"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0.6.4"])
  s.add_development_dependency(%q<generator_spec>.freeze, ["~> 0.8"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
end
