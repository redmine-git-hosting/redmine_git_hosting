# frozen_string_literal: true

module SlimLint
  # Checks for forbidden tags.
  class Linter::Tag < Linter
    include LinterRegistry

    on [:html, :tag] do |sexp|
      _, _, name = sexp

      forbidden_tags = config['forbidden_tags']
      forbidden_tags.each do |forbidden_tag|
        next unless name[/^#{forbidden_tag}$/i]

        report_lint(sexp, "Forbidden tag `#{name}` found")
      end
    end
  end
end
