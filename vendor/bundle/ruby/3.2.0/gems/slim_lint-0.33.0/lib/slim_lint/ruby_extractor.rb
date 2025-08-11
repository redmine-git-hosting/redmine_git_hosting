# frozen_string_literal: true

module SlimLint
  # Utility class for extracting Ruby script from a Slim template that can then
  # be linted with a Ruby linter (i.e. is "legal" Ruby).
  #
  # The goal is to turn this:
  #
  #    - if items.any?
  #      table#items
  #      - for item in items
  #        tr
  #          td.name = item.name
  #          td.price = item.price
  #    - else
  #       p No items found.
  #
  # into (something like) this:
  #
  #    if items.any?
  #      for item in items
  #        puts item.name
  #        puts item.price
  #    else
  #      puts 'No items found'
  #    end
  #
  # The translation won't be perfect, and won't make any real sense, but the
  # relationship between variable declarations/uses and the flow control graph
  # will remain intact.
  class RubyExtractor
    include SexpVisitor
    extend SexpVisitor::DSL

    # Stores the extracted source and a map of lines of generated source to the
    # original source that created them.
    #
    # @attr_reader source [String] generated source code
    # @attr_reader source_map [Hash] map of line numbers from generated source
    #   to original source line number
    RubySource = Struct.new(:source, :source_map)

    # Extracts Ruby code from Sexp representing a Slim document.
    #
    # @param sexp [SlimLint::Sexp]
    # @return [SlimLint::RubyExtractor::RubySource]
    def extract(sexp)
      trigger_pattern_callbacks(sexp)
      RubySource.new(@source_lines.join("\n"), @source_map)
    end

    on_start do |_sexp|
      @source_lines = []
      @source_map = {}
      @line_count = 0
      @dummy_puts_count = 0
    end

    on [:html, :doctype] do |sexp|
      append_dummy_puts(sexp)
    end

    on [:html, :tag] do |sexp|
      append_dummy_puts(sexp)
    end

    on [:static] do |sexp|
      append_dummy_puts(sexp)
    end

    on [:dynamic] do |sexp|
      _, ruby = sexp
      append(ruby, sexp)
    end

    on [:code] do |sexp|
      _, ruby = sexp
      append(ruby, sexp)
    end

    private

    # Append code to the buffer.
    #
    # @param code [String]
    # @param sexp [SlimLint::Sexp]
    def append(code, sexp)
      return if code.empty?

      original_line = sexp.line

      # For code that spans multiple lines, the resulting code will span
      # multiple lines, so we need to create a mapping for each line.
      code.split("\n").each_with_index do |line, index|
        @source_lines << line
        @line_count += 1
        @source_map[@line_count] = original_line + index
      end
    end

    def append_dummy_puts(sexp)
      append("_slim_lint_puts_#{@dummy_puts_count}", sexp)
      @dummy_puts_count += 1
    end
  end
end
