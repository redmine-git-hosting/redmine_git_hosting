# frozen_string_literal: true

require 'find'

module SlimLint
  # Finds Slim files that should be linted given a specified list of paths, glob
  # patterns, and configuration.
  class FileFinder
    # List of extensions of files to include under a directory when a directory
    # is specified instead of a file.
    VALID_EXTENSIONS = %w[.slim].freeze

    # Create a file finder using the specified configuration.
    #
    # @param config [SlimLint::Configuration]
    def initialize(config)
      @config = config
    end

    # Return list of files to lint given the specified set of paths and glob
    # patterns.
    # @param patterns [Array<String>]
    # @param excluded_patterns [Array<String>]
    # @raise [SlimLint::Exceptions::InvalidFilePath]
    # @return [Array<String>] list of actual files
    def find(patterns, excluded_patterns)
      excluded_patterns = excluded_patterns.map { |pattern| normalize_path(pattern) }

      extract_files_from(patterns).reject do |file|
        SlimLint::Utils.any_glob_matches?(excluded_patterns, file)
      end
    end

    private

    # Extract the list of matching files given the list of glob patterns, file
    # paths, and directories.
    #
    # @param patterns [Array<String>]
    # @return [Array<String>]
    def extract_files_from(patterns) # rubocop:disable Metrics/MethodLength
      files = []

      patterns.each do |pattern|
        if File.file?(pattern)
          files << pattern
        else
          begin
            ::Find.find(pattern) do |file|
              files << file if slim_file?(file)
            end
          rescue ::Errno::ENOENT
            # File didn't exist; it might be a file glob pattern
            matches = ::Dir.glob(pattern)
            if matches.any?
              files += matches
            else
              # One of the paths specified does not exist; raise a more
              # descriptive exception so we know which one
              raise SlimLint::Exceptions::InvalidFilePath,
                    "File path '#{pattern}' does not exist"
            end
          end
        end
      end

      files.uniq.sort.map { |file| normalize_path(file) }
    end

    # Trim "./" from the front of relative paths.
    #
    # @param path [String]
    # @return [String]
    def normalize_path(path)
      path.start_with?(".#{File::SEPARATOR}") ? path[2..] : path
    end

    # Whether the given file should be treated as a Slim file.
    #
    # @param file [String]
    # @return [Boolean]
    def slim_file?(file)
      return false unless ::FileTest.file?(file)

      VALID_EXTENSIONS.include?(::File.extname(file))
    end
  end
end
