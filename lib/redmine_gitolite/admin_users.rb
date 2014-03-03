module RedmineGitolite

  class AdminUsers < Admin

    include RedmineGitolite::AdminUsersHelper


    def add_ssh_key
      object = User.find_by_id(@object_id)
      update_user(object)
    end


    def update_ssh_keys
      object = User.find_by_id(@object_id)
      update_user(object)
    end


    def delete_ssh_key
      object = @object_id
      delete_ssh_keys(object)
    end


    def update_all_ssh_keys_forced
      object = User.all
      update_ssh_keys(object)
    end


    private


    def update_user(user)
      wrapped_transaction do
        handle_user_update(user)
        gitolite_admin_repo_commit("#{user.login}")
      end
    end


    def delete_ssh_keys(ssh_key)
      wrapped_transaction do
        handle_ssh_key_delete(ssh_key)
        gitolite_admin_repo_commit("#{ssh_key['title']}")
      end
    end


    def update_all_ssh_keys(users)
      wrapped_transaction do
        users.each do |user|
          handle_user_update(user)
          gitolite_admin_repo_commit("#{user.login}")
        end
      end
    end

  end
end
