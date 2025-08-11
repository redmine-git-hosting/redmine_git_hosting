# frozen_string_literal: true

module SlimLint::Matcher
  # Represents a Sexp pattern implementing complex matching logic.
  #
  # Subclasses can implement custom logic to create complex matches that can be
  # reused across linters, DRYing up matching code.
  #
  # @abstract
  class Base
    # Whether this matcher matches the specified object.
    #
    # This must be implemented by subclasses.
    #
    # @param other [Object]
    # @return [Boolean]
    def match?(*)
      raise NotImplementedError, 'Matcher must implement `match?`'
    end
  end
end
