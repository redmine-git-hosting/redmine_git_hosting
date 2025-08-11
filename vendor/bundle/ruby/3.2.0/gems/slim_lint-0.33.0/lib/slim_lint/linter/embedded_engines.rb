# frozen_string_literal: true

module SlimLint
  # Checks for forbidden embedded engines.
  class Linter::EmbeddedEngines < Linter
    include LinterRegistry

    MESSAGE = 'Forbidden embedded engine `%s` found'

    on_start do |_sexp|
      forbidden_engines = config['forbidden_engines']
      dummy_node = Struct.new(:line)
      document.source_lines.each_with_index do |line, index|
        forbidden_engines.each do |forbidden_engine|
          next unless line =~ /^\s*#{forbidden_engine}.*:\s*$/

          report_lint(dummy_node.new(index + 1), MESSAGE % forbidden_engine)
        end
      end
    end
  end
end
