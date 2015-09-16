module RedmineGitHosting
  module GitoliteHandlers
    module SshKeys
      class AddSshKey < Base

        def call
          repo_key = find_gitolite_key(key.owner, key.location)

          # Add it if not found
          if repo_key.nil?
            admin.add_key(build_gitolite_key(key))
          else
            logger.info("#{context} : SSH key '#{key.owner}@#{key.location}' already exists in Gitolite, update it ...")
            repo_key.type     = key.type
            repo_key.blob     = key.blob
            repo_key.email    = key.email
            repo_key.owner    = key.owner
            repo_key.location = key.location
          end
        end

      end
    end
  end
end
