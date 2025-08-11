# frozen_string_literal: true

# Global application constants.
module SlimLint
  HOME = File.expand_path(File.join(File.dirname(__FILE__), '..', '..')).freeze
  APP_NAME = 'slim-lint'

  REPO_URL = 'https://github.com/sds/slim-lint'
  BUG_REPORT_URL = "#{REPO_URL}/issues"
end
