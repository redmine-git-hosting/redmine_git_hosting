# frozen_string_literal: true

module SlimLint::Matcher
  # Will match anything, acting as a wildcard.
  class Anything < Base
    # @see {SlimLint::Matcher::Base#match?}
    def match?(*)
      true
    end
  end
end
