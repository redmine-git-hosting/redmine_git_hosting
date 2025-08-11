# frozen_string_literal: true

module SlimLint
  # Reports on missing strict locals magic line in Slim templates.
  class Linter::StrictLocalsMissing < Linter
    include LinterRegistry

    on_start do |_sexp|
      unless document.source =~ %r{/#\s+locals:\s+\(.*\)}
        dummy_node = Struct.new(:line)
        report_lint(dummy_node.new(1), 'Strict locals magic line is missing')
      end
    end
  end
end
