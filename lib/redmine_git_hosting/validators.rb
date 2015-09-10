module RedmineGitHosting
  module Validators
    extend self

    # Validate a Git SSH urls
    # ssh://git@redmine.example.org/project1/project2/project3/project4.git
    # ssh://git@redmine.example.org:2222/project1/project2/project3/project4.git
    #
    GIT_SSH_URL_REGEX = /\A(ssh:\/\/)([\w\-\.@]+)(\:[\d]+)?([\w\/\-\.~]+)(\.git)?\z/i

    def valid_git_ssh_url?(url)
      url.match(GIT_SSH_URL_REGEX)
    end


    # Validate a domain name with optional port
    # redmine.example.net
    # redmine.example.net:8080
    #
    DOMAIN_REGEX = /\A[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*(:\d+)?\z/i

    def valid_domain?(domain)
      domain.match(DOMAIN_REGEX)
    end


    # Validate an email address
    # '3a+2b-1.0c__@0FoO.BaR.iT'
    #
    EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

    def valid_email?(email)
      email.match(EMAIL_REGEX)
    end


    # Validate that data passed through forms are boolean-like.
    #
    BOOLEAN_FIELDS = ['true', 'false']

    def valid_boolean_field?(field)
      BOOLEAN_FIELDS.include?(field)
    end

  end
end
