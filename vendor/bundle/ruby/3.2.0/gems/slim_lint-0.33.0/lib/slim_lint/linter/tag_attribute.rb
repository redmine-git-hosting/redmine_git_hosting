# frozen_string_literal: true

module SlimLint
  # Checks for forbidden tag attributes.
  class Linter::TagAttribute < Linter
    include LinterRegistry

    on [:html, :attr] do |sexp|
      _, _, name = sexp

      forbidden_attributes = config['forbidden_attributes']
      forbidden_attributes.each do |forbidden_attribute|
        next unless name[/^#{forbidden_attribute}$/i]

        report_lint(sexp, "Forbidden tag attribute `#{name}` found")
      end
    end
  end
end
