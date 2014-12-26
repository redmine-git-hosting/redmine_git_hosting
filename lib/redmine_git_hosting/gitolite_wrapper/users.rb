module RedmineGitHosting
  module GitoliteWrapper
    class Users < Admin

      attr_reader :ssh_key
      attr_reader :ssh_keys


      def initialize(*args)
        super

        if object_id.is_a?(Hash)
          @ssh_key = object_id.symbolize_keys
        elsif object_id == 'all'
          @ssh_keys = GitolitePublicKey.all
        else
          @ssh_key = GitolitePublicKey.find_by_id(object_id)
        end
      end


      def add_ssh_key
        logger.info("Adding SSH key #{ssh_key.identifier}")
        admin.transaction do
          add_gitolite_key(ssh_key)
          gitolite_admin_repo_commit("Add SSH key : #{ssh_key.identifier}")
        end
      end


      def delete_ssh_key
        logger.info("Deleting SSH key #{ssh_key[:identifier]}")
        admin.transaction do
          remove_gitolite_key(ssh_key)
          gitolite_admin_repo_commit("Delete SSH key : #{ssh_key[:identifier]}")
        end
      end


      def resync_all_ssh_keys
        admin.transaction do
          ssh_keys.each do |ssh_key|
            add_gitolite_key(ssh_key)
            gitolite_admin_repo_commit("Add SSH key : #{ssh_key.identifier}")
          end
        end
      end


      private


        def add_gitolite_key(key)
          repo_key = keys_for_owner(key.owner).find_all{|k| k.location == key.location && k.owner == key.owner}.first

          # Add it if not found
          unless repo_key
            repo_key = build_gitolite_key(key)
            admin.add_key(repo_key)
          else
            logger.info("#{action} : SSH key '#{key.owner}@#{key.location}' already exists in Gitolite, update it ...")
            repo_key.type     = key_type(key.key)
            repo_key.blob     = key_blob(key.key)
            repo_key.email    = key_email(key.key)
            repo_key.owner    = key.owner
            repo_key.location = key.location
          end
        end


        def remove_gitolite_key(key)
          repo_key = keys_for_owner(key[:owner]).find_all{|k| k.location == key[:location] && k.owner == key[:owner]}.first
          if repo_key
            admin.rm_key(repo_key)
          else
            logger.info("#{action} : SSH key '#{key[:owner]}@#{key[:location]}' does not exits in Gitolite, exit !")
          end
        end


        def build_gitolite_key(key)
          Gitolite::SSHKey.new(key_type(key.key), key_blob(key.key), key_email(key.key), key.owner, key.location)
        end


        def keys_for_owner(owner)
          admin.ssh_keys[owner]
        end


        def key_type(key)
          key.split(' ')[0]
        end


        def key_blob(key)
          key.split(' ')[1]
        end


        def key_email(key)
          key.split(' ')[2]
        end

    end
  end
end
