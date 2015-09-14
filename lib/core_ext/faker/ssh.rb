require 'sshkey'

module Faker
  class Ssh < Base
    flexible :ssh

    class << self

      def public_key
        generate_ssh_key[:public_key]
      end


      def private_key
        generate_ssh_key[:private_key]
      end


      def both_keys
        generate_ssh_key
      end


      private


        def generate_ssh_key
          key = SSHKey.generate(comment: "faker@#{Internet.domain_name}")
          { private_key: key.private_key, public_key: key.ssh_public_key }
        end

    end

  end
end
