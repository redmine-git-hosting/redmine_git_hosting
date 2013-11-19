module RedmineGitHosting
  module Patches
    module UserPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          has_many :gitolite_public_keys, :dependent => :destroy

          #before_destroy  :delete_ssh_keys, prepend: true
          #after_update    :update_ssh_keys
        end
      end

      module InstanceMethods

        private

        def update_ssh_keys
          GitHosting.logger.info "Rebuild SSH keys for user : '#{self.login}'"
          GitHosting.resync_gitolite({ :command => :update_ssh_keys, :object => self.id })

          project_list = Array.new
          self.projects_by_role.each do |role|
            role[1].each do |project|
              project_list.push(project.id)
            end
          end

          if project_list.length > 0
            GitHosting.logger.info "Update projects to add SSH access : '#{project_list.uniq}'"
            GitHosting.resync_gitolite({ :command => :update_projects, :object => project_list.uniq })
          end
        end


        def delete_ssh_keys
          GitHosting.logger.info "User '#{self.login}' has been deleted from Redmine delete ssh keys !" if self.gitolite_public_keys.any?

          self.gitolite_public_keys.each do |ssh_key|
            repo_key = Hash.new
            repo_key[:title]    = ssh_key.identifier
            repo_key[:key]      = ssh_key.key
            repo_key[:location] = ssh_key.location
            repo_key[:owner]    = ssh_key.owner
            GitHosting.logger.info "Delete SSH key #{ssh_key.identifier}"
            GitHosting.resync_gitolite({ :command => :delete_ssh_key, :object => repo_key })
          end
        end

      end

    end
  end
end

unless User.included_modules.include?(RedmineGitHosting::Patches::UserPatch)
  User.send(:include, RedmineGitHosting::Patches::UserPatch)
end
