# frozen_string_literal: true

module SlimLint
  # Checks for missing or superfluous spacing before and after control statements.
  class Linter::ControlStatementSpacing < Linter
    include LinterRegistry

    MESSAGE_OUTPUT = 'Please add a space before and after the `=`'
    MESSAGE_CONTROL = 'Please add a space after the `-`'

    on [:html, :tag, anything, [],
         [:slim, :output, anything, capture(:ruby, anything)]] do |sexp|
      # Fetch original Slim code that contains an element with a control statement.
      line = document.source_lines[sexp.line - 1]

      # Remove any Ruby code, because our regexp below must not match inside Ruby.
      ruby = captures[:ruby]
      line = line.sub(ruby, 'x')

      next if line =~ /[^ ] ==?<?>? [^ ]/

      report_lint(sexp, MESSAGE_OUTPUT)
    end

    on [:slim, :control] do |sexp|
      line = document.source_lines[sexp.line - 1]

      next if line =~ /^ *- [^ ]/

      report_lint(sexp, MESSAGE_CONTROL)
    end
  end
end
