# frozen_string_literal: true

module SlimLint
  class Linter::Zwsp < Linter
    include LinterRegistry

    MSG = 'Remove zero-width space'

    on_start do |_sexp|
      dummy_node = Struct.new(:line)
      document.source_lines.each_with_index do |line, index|
        next unless line.include?("\u200b")

        report_lint(dummy_node.new(index + 1), MSG)
      end
    end
  end
end
