# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version'

Gem::Specification.new do |s|
  s.name          = 'rubypants'
  s.version       = RubyPantsVersion::VERSION
  s.summary       = "RubyPants is a Ruby port of the smart-quotes library SmartyPants."
  s.description   = <<-EOF
The original "SmartyPants" is a free web publishing plug-in for
Movable Type, Blosxom, and BBEdit that easily translates plain ASCII
punctuation characters into "smart" typographic punctuation HTML
entities.
                    EOF
  s.authors       = [
                      "John Gruber",
                      "Chad Miller",
                      "Christian Neukirchen",
                      "Jeremy McNevin",
                      "Aron Griffis"
                    ]
  s.email         = 'jeremy@spokoino.net'
  s.files         = `git ls-files`.split($/)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  s.homepage      = 'https://github.com/jmcnevin/rubypants'
  s.license       = 'MIT'

  s.add_development_dependency('minitest')
end
