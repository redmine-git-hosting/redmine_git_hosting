module RedmineGitHosting
  module Validators
    extend self

    DOMAIN_REGEX   = /\A[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*(:\d+)?\z/i
    EMAIL_REGEX    = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
    BOOLEAN_FIELDS = ['true', 'false']


    def valid_email?(email)
      email.match(EMAIL_REGEX)
    end


    def valid_domain?(domain)
      domain.match(DOMAIN_REGEX)
    end

  end
end
