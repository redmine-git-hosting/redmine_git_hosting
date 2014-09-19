module RedmineGitolite

  module GitoliteWrapper

    class Users < Admin


      def add_ssh_key
        ssh_key = GitolitePublicKey.find_by_id(object_id)
        logger.info { "Adding SSH key #{ssh_key.identifier}" }
        admin.transaction do
          add_gitolite_key(ssh_key)
          gitolite_admin_repo_commit("Add SSH key : #{ssh_key.identifier}")
        end
      end


      def delete_ssh_key
        ssh_key = object_id.symbolize_keys
        logger.info { "Deleting SSH key #{ssh_key[:identifier]}" }
        admin.transaction do
          remove_gitolite_key(ssh_key)
          gitolite_admin_repo_commit("Delete SSH key : #{ssh_key[:identifier]}")
        end
      end


      def resync_all_ssh_keys
        ssh_keys = GitolitePublicKey.all
        admin.transaction do
          ssh_keys.each do |ssh_key|
            add_gitolite_key(ssh_key)
            gitolite_admin_repo_commit("Add SSH key : #{ssh_key.identifier}")
          end
        end
      end


      private


      def add_gitolite_key(key)
        parts     = key.key.split
        repo_keys = admin.ssh_keys[key.owner]
        repo_key  = repo_keys.find_all{|k| k.location == key.location && k.owner == key.owner}.first

        unless repo_key
          repo_key = Gitolite::SSHKey.new(parts[0], parts[1], parts[2], key.owner, key.location)
          admin.add_key(repo_key)
        else
          logger.info { "#{action} : SSH key '#{key.owner}@#{key.location}' already exists in Gitolite, update it ..." }
          repo_key.type, repo_key.blob, repo_key.email = parts
          repo_key.owner = key.owner
          repo_key.location = key.location
        end
      end


      def remove_gitolite_key(key)
        repo_keys = admin.ssh_keys[key[:owner]]
        repo_key  = repo_keys.find_all{|k| k.location == key[:location] && k.owner == key[:owner]}.first

        if repo_key
          admin.rm_key(repo_key)
        else
          logger.info { "#{action} : SSH key '#{key[:owner]}@#{key[:location]}' does not exits in Gitolite, exit !" }
        end
      end

    end
  end
end
