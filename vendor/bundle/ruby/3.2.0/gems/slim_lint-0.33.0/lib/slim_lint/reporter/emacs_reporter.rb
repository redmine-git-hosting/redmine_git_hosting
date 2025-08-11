# frozen_string_literal: true

module SlimLint
  # Outputs lints in format: {filename}:{line}:{column}: {kind}: {message}.
  class Reporter::EmacsReporter < Reporter
    def display_report(report)
      sorted_lints = report.lints.sort_by { |l| [l.filename, l.line] }

      sorted_lints.each do |lint|
        print_location(lint)
        print_type(lint)
        print_message(lint)
      end
    end

    private

    def print_location(lint)
      log.info lint.filename, false
      log.log ':', false
      log.bold lint.line, false
      log.log ':', false
      # TODO: change 1 to column number when linter will have this info.
      log.bold 1, false
      log.log ':', false
    end

    def print_type(lint)
      if lint.error?
        log.error ' E: ', false
      else
        log.warning ' W: ', false
      end
    end

    def print_message(lint)
      if lint.linter
        log.success("#{lint.linter.name}: ", false)
      end

      log.log lint.message
    end
  end
end
