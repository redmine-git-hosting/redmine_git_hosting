module RedmineGitHosting
  module GitoliteWrappers
    module Users
      class RegenerateSshKeys < GitoliteWrappers::Base

        def call
          GitolitePublicKey.all.each do |ssh_key|
            gitolite_accessor.destroy_ssh_key(ssh_key, bypass_sidekiq: true)
            ssh_key.reset_identifiers(skip_auto_increment: true)
            gitolite_accessor.create_ssh_key(ssh_key, bypass_sidekiq: true)
          end
        end

      end
    end
  end
end
