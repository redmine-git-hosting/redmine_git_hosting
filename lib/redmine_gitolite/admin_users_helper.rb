module RedmineGitolite

  module AdminUsersHelper

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
        repo_keys = @gitolite_admin.ssh_keys[key.owner]
        repo_key = repo_keys.find_all{|k| k.location == key.location && k.owner == key.owner}.first
        if repo_key
          logger.info { "#{@action} : SSH key '#{key.owner}' already exists in Gitolite, update it ..." }
          repo_key.type, repo_key.blob, repo_key.email = parts
          repo_key.owner = key.owner
          repo_key.location = key.location
        else
          logger.info { "#{@action} : SSH key '#{key.owner}' does not exist in Gitolite, create it ..." }
          repo_key = Gitolite::SSHKey.new(parts[0], parts[1], parts[2])
          repo_key.location = key.location
          repo_key.owner = key.owner
          @gitolite_admin.add_key repo_key
        end
      end
    end


    def remove_inactive_keys(keys)
      keys.each do |key|
        ssh_key = Hash.new
        ssh_key['owner']    = key.owner
        ssh_key['location'] = key.location
        logger.info { "#{@action} : removing inactive SSH key of '#{key.owner}'" }
        remove_inactive_key(ssh_key)
      end
    end


    def remove_inactive_key(key)
      repo_keys = @gitolite_admin.ssh_keys[key['owner']]
      repo_key = repo_keys.find_all{|k| k.location == key['location'] && k.owner == key['owner']}.first
      if repo_key
        logger.info { "#{@action} : SSH key '#{key['owner']}' exists in Gitolite, delete it ..." }
        @gitolite_admin.rm_key repo_key
      else
        logger.info { "#{@action} : SSH key '#{key['owner']}' does not exits in Gitolite, exit !" }
        return false
      end
    end

  end
end
