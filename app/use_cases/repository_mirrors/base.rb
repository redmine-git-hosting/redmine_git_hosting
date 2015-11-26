module RepositoryMirrors
  class Base

    attr_reader :mirror
    attr_reader :repository


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
