# frozen_string_literal: true

# Load all slim-lint modules necessary to parse and lint a file.
# Ordering here can be important depending on class references in each module.

# Need to load slim before we can reference some classes or define filters
require 'slim'

require_relative 'slim_lint/constants'
require_relative 'slim_lint/exceptions'
require_relative 'slim_lint/configuration'
require_relative 'slim_lint/configuration_loader'
require_relative 'slim_lint/utils'
require_relative 'slim_lint/atom'
require_relative 'slim_lint/sexp'
require_relative 'slim_lint/file_finder'
require_relative 'slim_lint/linter_registry'
require_relative 'slim_lint/logger'
require_relative 'slim_lint/version'

# Load all filters (required by SlimLint::Engine)
Dir[File.expand_path('slim_lint/filters/*.rb', File.dirname(__FILE__))].sort.each do |file|
  require file
end

require_relative 'slim_lint/engine'
require_relative 'slim_lint/document'
require_relative 'slim_lint/capture_map'
require_relative 'slim_lint/sexp_visitor'
require_relative 'slim_lint/lint'
require_relative 'slim_lint/ruby_parser'
require_relative 'slim_lint/linter'
require_relative 'slim_lint/reporter'
require_relative 'slim_lint/report'
require_relative 'slim_lint/linter_selector'
require_relative 'slim_lint/runner'

# Load all matchers
require_relative 'slim_lint/matcher/base'
Dir[File.expand_path('slim_lint/matcher/*.rb', File.dirname(__FILE__))].sort.each do |file|
  require file
end

# Load all linters
Dir[File.expand_path('slim_lint/linter/*.rb', File.dirname(__FILE__))].sort.each do |file|
  require file
end

# Load all reporters
Dir[File.expand_path('slim_lint/reporter/*.rb', File.dirname(__FILE__))].sort.each do |file|
  require file
end
