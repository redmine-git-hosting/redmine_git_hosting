# frozen_string_literal: true

module RedmineGitHosting
  class GitAccessStatus
    attr_accessor :status, :message
    alias allowed? status

    def initialize(status, message = '')
      @status  = status
      @message = message
    end

    def to_json(*_args)
      { status: @status, message: @message }.to_json
    end
  end
end
