# -*- encoding: utf-8 -*-
# stub: creole 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "creole".freeze
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Lars Christensen".freeze, "Daniel Mendler".freeze]
  s.date = "2012-10-29"
  s.description = "Creole is a lightweight markup language (http://wikicreole.org/).".freeze
  s.email = ["larsch@belunktum.dk".freeze, "mail@daniel-mendler.de".freeze]
  s.extra_rdoc_files = ["README.creole".freeze]
  s.files = ["README.creole".freeze]
  s.homepage = "http://github.com/minad/creole".freeze
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Lightweight markup language".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 3

  s.add_development_dependency(%q<bacon>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
end
