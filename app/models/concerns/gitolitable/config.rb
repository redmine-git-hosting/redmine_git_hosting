module Gitolitable
  module Config
    extend ActiveSupport::Concern

    def git_config
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


    def gitolite_options
      repo_conf = {}

      git_option_keys.each do |option|
        repo_conf[option.key] = option.value
      end if git_option_keys.any?

      repo_conf
    end


    def owner
      { name: Setting['app_title'], email: Setting['mail_from'] }
    end


    def github_payload
      {
        repository: {
          owner:        owner,
          description:  project.description,
          fork:         false,
          forks:        0,
          homepage:     project.homepage,
          name:         redmine_name,
          open_issues:  project.issues.open.length,
          watchers:     0,
          private:      !project.is_public,
          url:          repository_url
        },
        pusher: owner,
      }
    end


    def repository_url
      Rails.application.routes.url_helpers.url_for(
        controller: 'repositories', action: 'show',
        id: project, repository_id: identifier_param,
        only_path: false, host: Setting['host_name'], protocol: Setting['protocol']
      )
    end

  end
end
