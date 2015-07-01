module RedmineGitHosting
  module GitoliteWrappers
    module Users
      class ResyncSshKeys < GitoliteWrappers::Base

        def call
          admin.transaction do
            GitolitePublicKey.all.each do |ssh_key|
              create_gitolite_key(ssh_key)
              gitolite_admin_repo_commit("Add SSH key : #{ssh_key.identifier}")
            end
          end
        end

      end
    end
  end
end
