# frozen_string_literal: true

module SlimLint
  # This linter checks for two or more consecutive blank lines
  # and for the first blank line in file.
  class Linter::EmptyLines < Linter
    include LinterRegistry

    on_start do |_sexp|
      dummy_node = Struct.new(:line)

      was_empty = true
      document.source.lines.each_with_index do |line, i|
        if line.blank?
          if was_empty
            report_lint(dummy_node.new(i + 1),
                        'Extra empty line detected')
          end
          was_empty = true
        else
          was_empty = false
        end
      end
    end
  end
end
