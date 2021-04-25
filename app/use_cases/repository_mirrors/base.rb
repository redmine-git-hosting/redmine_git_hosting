# frozen_string_literal: true

module RepositoryMirrors
  class Base
    attr_reader :mirror, :repository

    def initialize(mirror)
      @mirror     = mirror
      @repository = mirror.repository
    end

    class << self
      def call(mirror)
        new(mirror).call
      end
    end

    def call
      raise NotImplementedError
    end
  end
end
