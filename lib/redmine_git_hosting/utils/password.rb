require 'securerandom'

module RedmineGitHosting::Utils
  module Password

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def generate_secret(length)
        length = length.to_i
        secret = SecureRandom.base64(length)
        secret = secret.gsub(/[\=\_\-\+\/]/, '')
        secret = secret.split(//).sample(length - 1).join('')
        secret
      end

    end

  end
end
