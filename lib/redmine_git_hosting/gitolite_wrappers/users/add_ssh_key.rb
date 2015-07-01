module RedmineGitHosting
  module GitoliteWrappers
    module Users
      class AddSshKey < GitoliteWrappers::Base

        def call
          logger.info("Adding SSH key '#{ssh_key.identifier}'")
          admin.transaction do
            create_gitolite_key(ssh_key)
            gitolite_admin_repo_commit("Add SSH key : #{ssh_key.identifier}")
          end
        end


        def ssh_key
          @ssh_key ||= GitolitePublicKey.find_by_id(object_id)
        end

      end
    end
  end
end
