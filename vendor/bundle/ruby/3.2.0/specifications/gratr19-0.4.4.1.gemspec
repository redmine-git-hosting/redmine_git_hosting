# -*- encoding: utf-8 -*-
# stub: gratr19 0.4.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "gratr19".freeze
  s.version = "0.4.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Shawn Garbett".freeze, "Ankur Sethi".freeze]
  s.date = "2012-03-28"
  s.description = "GRATR is a framework for graph data structures and algorithms.\n\nThis library is a fork of RGL. This version utilizes\nRuby blocks and duck typing to greatly simplfy the code. It also supports\nexport to DOT format for display as graphics.\n\nGRATR currently contains a core set of algorithm patterns:\n\n * Breadth First Search \n * Depth First Search \n * A* Search\n * Floyd-Warshall\n * Best First Search\n * Djikstra's Algorithm\n * Lexicographic Search\n\nThe algorithm patterns by themselves do not compute any meaningful quantities\nover graphs, they are merely building blocks for constructing graph\nalgorithms. The graph algorithms in GRATR currently include:\n\n * Topological Sort \n * Strongly Connected Components \n * Transitive Closure\n * Rural Chinese Postman\n * Biconnected\n".freeze
  s.email = ["shawn@garbett.org".freeze, "ankursethi108@gmail.com".freeze]
  s.extra_rdoc_files = ["README".freeze]
  s.files = ["README".freeze]
  s.homepage = "https://github.com/amalagaura/gratr".freeze
  s.rdoc_options = ["--title".freeze, "GRATR - Ruby Graph Library".freeze, "--main".freeze, "README".freeze, "--line-numbers".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Graph Theory Ruby library".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version
end
