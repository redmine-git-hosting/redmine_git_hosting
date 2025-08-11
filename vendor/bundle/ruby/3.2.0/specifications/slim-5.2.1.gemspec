# -*- encoding: utf-8 -*-
# stub: slim 5.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "slim".freeze
  s.version = "5.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/slim-template/slim/issues", "changelog_uri" => "https://github.com/slim-template/slim/blob/main/CHANGES", "documentation_uri" => "https://rubydoc.info/gems/slim/frames", "funding_uri" => "https://github.com/sponsors/slim-template", "homepage_uri" => "https://slim-template.github.io/", "source_code_uri" => "https://github.com/slim-template/slim", "wiki_uri" => "https://github.com/slim-template/slim/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Mendler".freeze, "Andrew Stone".freeze, "Fred Wu".freeze]
  s.date = "2024-01-20"
  s.description = "Slim is a template language whose goal is reduce the syntax to the essential parts without becoming cryptic.".freeze
  s.email = ["mail@daniel-mendler.de".freeze, "andy@stonean.com".freeze, "ifredwu@gmail.com".freeze]
  s.executables = ["slimrb".freeze]
  s.files = ["bin/slimrb".freeze]
  s.homepage = "https://slim-template.github.io/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Slim is a template language.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<temple>.freeze, ["~> 0.10.0"])
  s.add_runtime_dependency(%q<tilt>.freeze, [">= 2.1.0"])
end
