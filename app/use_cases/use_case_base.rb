module UseCaseBase

  class << self
    def included(receiver)
      receiver.send(:include, InstanceMethods)
    end
  end


  module InstanceMethods

    def initialize(*)
      @errors = []
    end


    def call
      return self
    end


    def success?
      errors.empty?
    end


    def errors
      @errors.uniq
    end

  end

end
