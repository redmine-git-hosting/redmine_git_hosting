# frozen_string_literal: true

module SlimLint
  # Checks for file longer than a maximum number of lines.
  class Linter::FileLength < Linter
    include LinterRegistry

    MSG = 'File is too long. [%d/%d]'

    on_start do |_sexp|
      max_length = config['max']
      dummy_node = Struct.new(:line)

      count = document.source_lines.size
      if count > max_length
        report_lint(dummy_node.new(1), format(MSG, count, max_length))
      end
    end
  end
end
