# frozen_string_literal: true

module SlimLint
  # Abstract lint reporter. Subclass and override {#display_report} to
  # implement a custom lint reporter.
  #
  # @abstract
  class Reporter
    # Creates the reporter that will display the given report.
    #
    # @param logger [SlimLint::Logger]
    def initialize(logger)
      @log = logger
    end

    # Implemented by subclasses to display lints from a {SlimLint::Report}.
    #
    # @param report [SlimLint::Report]
    def display_report(report)
      raise NotImplementedError,
            "Implement `display_report` to display #{report}"
    end

    # Keep tracking all the descendants of this class for the list of available
    # reporters.
    #
    # @return [Array<Class>]
    def self.descendants
      @descendants ||= []
    end

    # Executed when this class is subclassed.
    #
    # @param descendant [Class]
    def self.inherited(descendant)
      descendants << descendant
    end

    private

    # @return [SlimLint::Logger] logger to send output to
    attr_reader :log
  end
end
