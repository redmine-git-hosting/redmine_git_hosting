# frozen_string_literal: true

module SlimLint
  # Searches for control statements with no code.
  class Linter::EmptyControlStatement < Linter
    include LinterRegistry

    on [:slim, :control] do |sexp|
      _, _, code = sexp
      next unless code[/\A\s*\Z/]

      report_lint(sexp, 'Empty control statement can be removed')
    end
  end
end
