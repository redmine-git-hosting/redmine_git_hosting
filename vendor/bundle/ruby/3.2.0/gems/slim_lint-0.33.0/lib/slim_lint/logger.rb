# frozen_string_literal: true

module SlimLint
  # Encapsulates all communication to an output source.
  class Logger
    # Whether colored output via ANSI escape sequences is enabled.
    # @return [true,false]
    attr_accessor :color_enabled

    # Creates a logger which outputs nothing.
    # @return [SlimLint::Logger]
    def self.silent
      new(File.open('/dev/null', 'w'))
    end

    # Creates a new {SlimLint::Logger} instance.
    #
    # @param out [IO] the output destination.
    def initialize(out)
      @out = out
    end

    # Print the specified output.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    def log(output, newline = true)
      @out.print(output)
      @out.print("\n") if newline
    end

    # Print the specified output in bold face.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param args [Array<String>]
    def bold(*args)
      color('1', *args)
    end

    # Print the specified output in a color indicative of error.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param args [Array<String>]
    def error(*args)
      color(31, *args)
    end

    # Print the specified output in a bold face and color indicative of error.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param args [Array<String>]
    def bold_error(*args)
      color('1;31', *args)
    end

    # Print the specified output in a color indicative of success.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param args [Array<String>]
    def success(*args)
      color(32, *args)
    end

    # Print the specified output in a color indicative of a warning.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param args [Array<String>]
    def warning(*args)
      color(33, *args)
    end

    # Print the specified output in a color indicating information.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param args [Array<String>]
    def info(*args)
      color(36, *args)
    end

    # Print a blank line.
    def newline
      log('')
    end

    # Whether this logger is outputting to a TTY.
    #
    # @return [true,false]
    def tty?
      @out.respond_to?(:tty?) && @out.tty?
    end

    private

    # Print output in the specified color.
    #
    # @param code [Integer,String] ANSI color code
    # @param output [String] output to print
    # @param newline [Boolean] whether to append a newline
    def color(code, output, newline = true)
      log(color_enabled ? "\033[#{code}m#{output}\033[0m" : output, newline)
    end
  end
end
