module RedmineGitHosting
  module GitoliteHandlers
    module SshKeys
      class Base

        attr_reader :admin
        attr_reader :key
        attr_reader :context


        def initialize(admin, key, context)
          @admin   = admin
          @key     = key
          @context = context
        end


        class << self

          def call(admin, key, context)
            new(admin, key, context).call
          end

        end


        def call
          raise NotImplementedError
        end


        private


          def logger
            RedmineGitHosting.logger
          end


          def find_gitolite_key(owner, location)
            admin.ssh_keys[owner].find_all { |k| k.location == location && k.owner == owner }.first
          end


          def build_gitolite_key(key)
            ::Gitolite::SSHKey.new(key.type, key.blob, key.email, key.owner, key.location)
          end

      end
    end
  end
end
