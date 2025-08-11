# -*- encoding: utf-8 -*-
# stub: github-markup 5.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "github-markup".freeze
  s.version = "5.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Wanstrath".freeze]
  s.date = "2024-06-17"
  s.description = "This gem is used by GitHub to render any fancy markup such as Markdown,\nTextile, Org-Mode, etc. Fork it and add your own!\n".freeze
  s.email = "chris@ozmm.org".freeze
  s.executables = ["github-markup".freeze]
  s.files = ["bin/github-markup".freeze]
  s.homepage = "https://github.com/github/markup".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "The code GitHub uses to render README.markup".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, ["~> 12"])
  s.add_development_dependency(%q<activesupport>.freeze, ["~> 7.1.3.4"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.4", ">= 5.4.3"])
  s.add_development_dependency(%q<html-pipeline>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<sanitize>.freeze, [">= 4.6.3"])
  s.add_development_dependency(%q<nokogiri>.freeze, ["~> 1.16.5"])
  s.add_development_dependency(%q<nokogiri-diff>.freeze, ["~> 0.3.0"])
  s.add_development_dependency(%q<github-linguist>.freeze, [">= 7.1.3"])
end
