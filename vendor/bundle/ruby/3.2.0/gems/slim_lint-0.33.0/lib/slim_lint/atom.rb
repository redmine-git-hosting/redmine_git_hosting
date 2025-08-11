# frozen_string_literal: true

module SlimLint
  # Represents an atomic, childless, literal value within an S-expression.
  #
  # This creates a light wrapper around literal values of S-expressions so we
  # can make an {Atom} quack like a {Sexp} without being an {Sexp}.
  class Atom
    # Stores the line number of the code in the original document that this Atom
    # came from.
    attr_accessor :line

    # Creates an atom from the specified value.
    #
    # @param value [Object]
    def initialize(value)
      @value = value
    end

    # Returns whether this atom is equivalent to another object.
    #
    # This defines a helper which unwraps the inner value of the atom to compare
    # against a literal value, saving us having to do it ourselves everywhere
    # else.
    #
    # @param other [Object]
    # @return [Boolean]
    def ==(other)
      @value == (other.is_a?(Atom) ? other.instance_variable_get(:@value) : other)
    end

    # Returns whether this atom matches the given Sexp pattern.
    #
    # This exists solely to make an {Atom} quack like a {Sexp}, so we don't have
    # to manually check the type when doing comparisons elsewhere.
    #
    # @param [Array, Object]
    # @return [Boolean]
    def match?(pattern)
      # Delegate matching logic if we're comparing against a matcher
      if pattern.is_a?(SlimLint::Matcher::Base)
        return pattern.match?(@value)
      end

      @value == pattern
    end

    # Displays the string representation the value this {Atom} wraps.
    #
    # @return [String]
    def to_s
      @value.to_s
    end

    # Displays a string representation of this {Atom} suitable for debugging.
    #
    # @return [String]
    def inspect
      "<#Atom #{@value.inspect}>"
    end

    # Redirect methods to the value this {Atom} wraps.
    #
    # Again, this is for convenience so we don't need to manually unwrap the
    # value ourselves. It's pretty magical, but results in much DRYer code.
    #
    # @param method_sym [Symbol] method that was called
    # @param args [Array]
    # @yield block that was passed to the method
    def method_missing(method_sym, *args, &block)
      if @value.respond_to?(method_sym)
        @value.send(method_sym, *args, &block)
      else
        super
      end
    end

    # @param method_name [String,Symbol] method name
    # @param args [Array]
    def respond_to_missing?(method_name, *args)
      @value.__send__(:respond_to_missing?, method_name, *args) || super
    end

    # Return whether this {Atom} or the value it wraps responds to the given
    # message.
    #
    # @param method_sym [Symbol]
    # @param include_private [Boolean]
    # @return [Boolean]
    def respond_to?(method_sym, include_private = false)
      super || @value.respond_to?(method_sym, include_private)
    end
  end
end
