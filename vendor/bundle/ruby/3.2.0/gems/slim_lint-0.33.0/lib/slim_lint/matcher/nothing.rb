# frozen_string_literal: true

module SlimLint::Matcher
  # Does not match anything.
  #
  # This is used in specs.
  class Nothing < Base
    # @see {SlimLint::Matcher::Base#match?}
    def match?(*)
      false
    end
  end
end
