module RedmineGitHosting
  module GitoliteHandlers
    module SshKeys
      class DeleteSshKey < Base

        def call
          repo_key = find_gitolite_key(key[:owner], key[:location])

          # Remove it if found
          if repo_key
            admin.rm_key(repo_key)
          else
            logger.info("#{context} : SSH key '#{key[:owner]}@#{key[:location]}' does not exits in Gitolite, exit !")
          end
        end

      end
    end
  end
end
