# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'

require_relative 'constants'

module SlimLint
  # Rake task interface for slim-lint command line interface.
  #
  # @example
  #   # Add the following to your Rakefile...
  #   require 'slim_lint/rake_task'
  #
  #   SlimLint::RakeTask.new do |t|
  #     t.config = 'path/to/custom/slim-lint.yml'
  #     t.files = %w[app/views/**/*.slim custom/*.slim]
  #     t.quiet = true # Don't display output from slim-lint
  #   end
  #
  #   # ...and then execute from the command line:
  #   rake slim_lint
  #
  # You can also specify the list of files as explicit task arguments:
  #
  # @example
  #   # Add the following to your Rakefile...
  #   require 'slim_lint/rake_task'
  #
  #   SlimLint::RakeTask.new
  #
  #   # ...and then execute from the command line (single quotes prevent shell
  #   # glob expansion and allow us to have a space after commas):
  #   rake 'slim_lint[app/views/**/*.slim, other_files/**/*.slim]'
  #
  class RakeTask < Rake::TaskLib
    # Name of the task.
    # @return [String]
    attr_accessor :name

    # Configuration file to use.
    # @return [String]
    attr_accessor :config

    # List of files to lint (can contain shell globs).
    #
    # Note that this will be ignored if you explicitly pass a list of files as
    # task arguments via the command line or a task definition.
    # @return [Array<String>]
    attr_accessor :files

    # Whether output from slim-lint should not be displayed to the standard out
    # stream.
    # @return [true,false]
    attr_accessor :quiet

    # Create the task so it exists in the current namespace.
    #
    # @param name [Symbol] task name
    def initialize(name = :slim_lint)
      @name = name
      @files = ['.'] # Search for everything under current directory by default
      @quiet = false

      yield self if block_given?

      define
    end

    private

    # Defines the Rake task.
    def define
      desc default_description unless ::Rake.application.last_description

      task(name, [:files]) do |_task, task_args|
        # Lazy-load so task doesn't affect Rakefile load time
        require_relative '../slim_lint'
        require_relative 'cli'

        run_cli(task_args)
      end
    end

    # Executes the CLI given the specified task arguments.
    #
    # @param task_args [Rake::TaskArguments]
    def run_cli(task_args)
      cli_args = ['--config', config] if config

      logger = quiet ? SlimLint::Logger.silent : SlimLint::Logger.new($stdout)
      result = SlimLint::CLI.new(logger).run(Array(cli_args) + files_to_lint(task_args))

      fail "#{SlimLint::APP_NAME} failed with exit code #{result}" unless result == 0
    end

    # Returns the list of files that should be linted given the specified task
    # arguments.
    #
    # @param task_args [Rake::TaskArguments]
    def files_to_lint(task_args)
      # NOTE: we're abusing Rake's argument handling a bit here. We call the
      # first argument `files` but it's actually only the first file--we pull
      # the rest out of the `extras` from the task arguments. This is so we
      # can specify an arbitrary list of files separated by commas on the
      # command line or in a custom task definition.
      explicit_files = Array(task_args[:files]) + Array(task_args.extras)

      explicit_files.any? ? explicit_files : files
    end

    # Friendly description that shows the full command that will be executed.
    #
    # This allows us to change the information displayed by `rake --tasks` based
    # on the options passed to the constructor which defined the task.
    #
    # @return [String]
    def default_description
      description = "Run `#{SlimLint::APP_NAME}"
      description += " --config #{config}" if config
      description += " #{files.join(' ')}" if files.any?
      description += ' [files...]`'
      description
    end
  end
end
