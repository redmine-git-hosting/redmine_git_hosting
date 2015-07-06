module Settings
  class Base
    unloadable

    attr_reader :old_valuehash
    attr_reader :valuehash


    def initialize(old_valuehash, valuehash, opts = {})
      @old_valuehash = old_valuehash
      @valuehash     = valuehash
    end


    class << self

      def call(old_valuehash, valuehash, opts = {})
        new(old_valuehash, valuehash, opts).call
      end

    end


    def call
      raise NotImplementedError
    end

  end
end
