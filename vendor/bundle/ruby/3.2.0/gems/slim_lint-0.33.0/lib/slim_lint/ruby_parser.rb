# frozen_string_literal: true

require 'rubocop'
require 'rubocop/ast/builder'

def require_parser(path)
  prev = $VERBOSE
$VERBOSE = nil
  require "parser/#{path}"
ensure
  $VERBOSE = prev
end

module SlimLint
  # Parser for the Ruby language.
  #
  # This provides a convenient wrapper around the `parser` gem and the
  # `astrolabe` integration to go with it. It is intended to be used for linter
  # checks that require deep inspection of Ruby code.
  class RubyParser
    # Creates a reusable parser.
    def initialize
      require_parser('current')
      @builder = ::RuboCop::AST::Builder.new
      @parser = ::Parser::CurrentRuby.new(@builder)
    end

    # Parse the given Ruby source into an abstract syntax tree.
    #
    # @param source [String] Ruby source code
    # @return [Array] syntax tree in the form returned by Parser gem
    def parse(source)
      buffer = ::Parser::Source::Buffer.new('(string)')
      buffer.source = source

      @parser.reset
      @parser.parse(buffer)
    end
  end
end
