# frozen_string_literal: true

module SlimLint
  # Base implementation for all lint checks.
  #
  # @abstract
  class Linter
    # Include definitions for Sexp pattern-matching helpers.
    include SexpVisitor
    extend SexpVisitor::DSL

    # List of lints reported by this linter.
    #
    # @todo Remove once spec/support/shared_linter_context returns an array of
    #   lints for the subject instead of the linter itself.
    attr_reader :lints

    # Initializes a linter with the specified configuration.
    #
    # @param config [Hash] configuration for this linter
    def initialize(config)
      @config = config
      @lints = []
    end

    # Runs the linter against the given Slim document.
    #
    # @param document [SlimLint::Document]
    def run(document)
      @document = document
      @lints = []
      @disabled_lines = nil
      trigger_pattern_callbacks(document.sexp)
      @lints
    end

    # Returns the simple name for this linter.
    #
    # @return [String]
    def name
      self.class.name.split('::').last
    end

    private

    attr_reader :config, :document

    # Record a lint for reporting back to the user.
    #
    # @param node [#line] node to extract the line number from
    # @param message [String] error/warning to display to the user
    def report_lint(node, message)
      return if disabled_for_line?(node.line)

      @lints << SlimLint::Lint.new(self, @document.file, node.line, message)
    end

    # Parse Ruby code into an abstract syntax tree.
    #
    # @param source [String] Ruby code to parse
    # @return [AST::Node]
    def parse_ruby(source)
      @ruby_parser ||= SlimLint::RubyParser.new
      @ruby_parser.parse(source)
    end

    def disabled_for_line?(line)
      disabled_lines.include?(line)
    end

    def disabled_lines
      @disabled_lines ||= begin
        currently_disabled = false
        @document.source_lines.each_with_index.each_with_object([]) do |pair, lines|
          line = pair[0]
          line_number = pair[1] + 1

          if line =~ %r{/ slim-lint:disable #{linter_name}}
            currently_disabled = true
          elsif line =~ %r{/ slim-lint:enable #{linter_name}}
            currently_disabled = false
          elsif currently_disabled
            lines << line_number
          end
        end
      end
    end

    def linter_name
      @linter_name ||= self.class.name.split('::').last
    end
  end
end
