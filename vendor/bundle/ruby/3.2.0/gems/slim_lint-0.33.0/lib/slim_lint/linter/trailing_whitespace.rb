# frozen_string_literal: true

module SlimLint
  # Checks for trailing whitespace.
  class Linter::TrailingWhitespace < Linter
    include LinterRegistry

    on_start do |_sexp|
      dummy_node = Struct.new(:line)

      document.source_lines.each_with_index do |line, index|
        next unless line =~ /\s+$/

        report_lint(dummy_node.new(index + 1),
                    'Line contains trailing whitespace')
      end
    end
  end
end
