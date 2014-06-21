module RedmineGitolite

  module GitoliteWrapper

    class Users < Admin


      def add_ssh_key
        user = User.find_by_id(@object_id)
        @admin.transaction do
          handle_user_update(user)
          gitolite_admin_repo_commit("#{user.login}")
        end
      end


      def update_ssh_keys
        user = User.find_by_id(@object_id)
        @admin.transaction do
          handle_user_update(user)
          gitolite_admin_repo_commit("#{user.login}")
        end
      end


      def delete_ssh_key
        ssh_key = @object_id
        @admin.transaction do
          handle_ssh_key_delete(ssh_key)
          gitolite_admin_repo_commit("#{ssh_key['title']}")
        end
      end


      def update_all_ssh_keys_forced
        users = User.includes(:gitolite_public_keys).all
        @admin.transaction do
          users.each do |user|
            if user.gitolite_public_keys.any?
              handle_user_update(user)
              gitolite_admin_repo_commit("#{user.login}")
            end
          end
        end
      end


      private


      def handle_user_update(user)
        add_active_keys(user.gitolite_public_keys.active)
        remove_inactive_keys(user.gitolite_public_keys.inactive)
      end


      def handle_ssh_key_delete(ssh_key)
        remove_inactive_key(ssh_key)
      end


      def add_active_keys(keys)
        keys.each do |key|
          parts = key.key.split
          repo_keys = @admin.ssh_keys[key.owner]
          repo_key = repo_keys.find_all{|k| k.location == key.location && k.owner == key.owner}.first
          if repo_key
            logger.info { "#{@action} : SSH key '#{key.owner}@#{key.location}' already exists in Gitolite, update it ..." }
            repo_key.type, repo_key.blob, repo_key.email = parts
            repo_key.owner = key.owner
            repo_key.location = key.location
          else
            logger.info { "#{@action} : SSH key '#{key.owner}@#{key.location}' does not exist in Gitolite, create it ..." }
            repo_key = Gitolite::SSHKey.new(parts[0], parts[1], parts[2])
            repo_key.location = key.location
            repo_key.owner = key.owner
            @admin.add_key(repo_key)
          end
        end
      end


      def remove_inactive_keys(keys)
        keys.each do |key|
          ssh_key = {}
          ssh_key['owner']    = key.owner
          ssh_key['location'] = key.location
          logger.info { "#{@action} : removing inactive SSH key of '#{key.owner}'" }
          remove_inactive_key(ssh_key)
        end
      end


      def remove_inactive_key(key)
        repo_keys = @admin.ssh_keys[key['owner']]
        repo_key  = repo_keys.find_all{|k| k.location == key['location'] && k.owner == key['owner']}.first

        if repo_key
          logger.info { "#{@action} : SSH key '#{key['owner']}@#{key['location']}' exists in Gitolite, delete it ..." }
          @admin.rm_key(repo_key)
        else
          logger.info { "#{@action} : SSH key '#{key['owner']}@#{key['location']}' does not exits in Gitolite, exit !" }
          return false
        end
      end

    end
  end
end
