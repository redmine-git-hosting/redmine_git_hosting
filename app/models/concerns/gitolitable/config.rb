module Gitolitable
  module Config
    extend ActiveSupport::Concern

    def gitolite_config
      repo_conf = {}

      # This is needed for all Redmine repositories
      repo_conf['redminegitolite.projectid']     = project.identifier.to_s
      repo_conf['redminegitolite.repositoryid']  = identifier || ''
      repo_conf['redminegitolite.repositorykey'] = gitolite_hook_key

      if project.active?

        repo_conf['http.uploadpack']  = clonable_via_http?.to_s
        repo_conf['http.receivepack'] = pushable_via_http?.to_s

        if git_notification_available?
          repo_conf['multimailhook.enabled']     = 'true'
          repo_conf['multimailhook.mailinglist'] = mailing_list.join(', ')
          repo_conf['multimailhook.from']        = sender_address
          repo_conf['multimailhook.emailPrefix'] = email_prefix
        else
          repo_conf['multimailhook.enabled'] = 'false'
        end

        git_config_keys.each do |git|
          repo_conf[git.key] = git.value
        end if git_config_keys.any?

      else
        # Disable repository
        repo_conf['http.uploadpack']       = 'false'
        repo_conf['http.receivepack']      = 'false'
        repo_conf['multimailhook.enabled'] = 'false'
      end

      repo_conf
    end


    def build_gitolite_permissions(old_perms = {})
      permissions_builder.build(self, gitolite_users, old_perms)
    end


    def backup_gitolite_permissions(gitolite_repo_conf)
      PermissionsBuilder::Base.get_permissions(gitolite_repo_conf)
    end


    private


      def permissions_builder
        if protected_branches_available?
          PermissionsBuilder::ProtectedBranches
        else
          PermissionsBuilder::Standard
        end
      end

  end
end
