# frozen_string_literal: true

# Collection of exceptions that can be raised by the application.
module SlimLint::Exceptions
  # Raised when a {Configuration} could not be loaded from a file.
  class ConfigurationError < StandardError; end

  # Raised when invalid/incompatible command line options are provided.
  class InvalidCLIOption < StandardError; end

  # Raised when an invalid file path is specified
  class InvalidFilePath < StandardError; end

  # Raised when the Slim parser is unable to parse a template.
  class ParseError < ::Slim::Parser::SyntaxError; end

  # Raised when attempting to execute `Runner` with options that would result in
  # no linters being enabled.
  class NoLintersError < StandardError; end
end
