# frozen_string_literal: true

module SlimLint
  # Searches for tab indentation
  class Linter::Tab < Linter
    include LinterRegistry

    MSG = 'Tab detected'

    on_start do |_sexp|
      dummy_node = Struct.new(:line)
      document.source_lines.each_with_index do |line, index|
        next unless line =~ /^( *)[\t ]*\t/

        report_lint(dummy_node.new(index + 1), MSG)
      end
    end
  end
end
