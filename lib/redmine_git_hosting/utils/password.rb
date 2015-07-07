require 'securerandom'

module RedmineGitHosting
  module Utils
    module Password
      extend self

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
