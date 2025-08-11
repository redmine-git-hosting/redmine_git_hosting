# frozen_string_literal: true

module SlimLint
  # Outputs lints in a format suitable for GitHub Actions.
  # See https://docs.github.com/en/actions/reference/workflow-commands-for-github-actions/.
  class Reporter::GithubReporter < Reporter
    def display_report(report)
      sorted_lints = report.lints.sort_by { |l| [l.filename, l.line] }

      sorted_lints.each do |lint|
        print_type(lint)
        print_location(lint)
        print_message(lint)
      end
    end

    private

    def print_type(lint)
      if lint.error?
        log.log '::error ', false
      else
        log.log '::warning ', false
      end
    end

    def print_location(lint)
      log.log "file=#{lint.filename},line=#{lint.line},", false
    end

    def print_message(lint)
      log.log 'title=Slim Lint', false
      log.log "::#{lint.message}"
    end
  end
end
