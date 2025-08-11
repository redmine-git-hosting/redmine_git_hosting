# frozen_string_literal: true

module SlimLint
  # Checks for unnecessary uses of the `div` tag where a class name or ID
  # already implies a div.
  class Linter::RedundantDiv < Linter
    include LinterRegistry

    MESSAGE = '`div` is redundant when %s attribute shortcut is present'

    on [:html, :tag, 'div',
         [:html, :attrs,
           [:html, :attr,
             capture(:attr_name, anything),
             [:static]]]] do |sexp|
      attr = captures[:attr_name]
      next unless %w[class id].include?(attr)

      report_lint(sexp, MESSAGE % attr)
    end
  end
end
