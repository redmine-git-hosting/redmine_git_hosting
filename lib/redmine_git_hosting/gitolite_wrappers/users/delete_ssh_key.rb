module RedmineGitHosting
  module GitoliteWrappers
    module Users
      class DeleteSshKey < GitoliteWrappers::Base

        def call
          logger.info("Deleting SSH key '#{ssh_key[:title]}'")
          admin.transaction do
            delete_gitolite_key(ssh_key)
            gitolite_admin_repo_commit("Delete SSH key : #{ssh_key[:title]}")
          end
        end


        def ssh_key
          @ssh_key ||= object_id.symbolize_keys
        end

      end
    end
  end
end
