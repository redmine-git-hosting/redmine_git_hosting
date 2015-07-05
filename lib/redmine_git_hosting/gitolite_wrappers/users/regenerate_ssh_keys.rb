module RedmineGitHosting
  module GitoliteWrappers
    module Users
      class RegenerateSshKeys < GitoliteWrappers::Base

        def call
          GitolitePublicKey.all.each do |ssh_key|
            GitoliteAccessor.destroy_ssh_key(ssh_key, bypass_sidekiq: true)
            ssh_key.reset_identifiers(skip_auto_increment: true)
            GitoliteAccessor.create_ssh_key(ssh_key, bypass_sidekiq: true)
          end
        end

      end
    end
  end
end
