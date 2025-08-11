# frozen_string_literal: true

module SlimLint
  # This linter looks for trailing blank lines and a final newline.
  class Linter::TrailingBlankLines < Linter
    include LinterRegistry

    on_start do |_sexp|
      dummy_node = Struct.new(:line)
      next if document.source.empty?

      if !document.source.end_with?("\n")
        report_lint(dummy_node.new(document.source_lines.size),
                    'No blank line in the end of file')
      elsif document.source.lines.last.blank?
        report_lint(dummy_node.new(document.source.lines.size),
                    'Multiple empty lines in the end of file')
      end
    end
  end
end
