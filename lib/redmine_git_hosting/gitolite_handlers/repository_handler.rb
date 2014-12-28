module RedmineGitHosting
  module GitoliteHandlers
    class RepositoryHandler

      attr_reader :repository
      attr_reader :gitolite_config
      attr_reader :action
      attr_reader :opts

      attr_reader :project
      attr_reader :notifier

      attr_reader :gitolite_repo_name
      attr_reader :gitolite_repo_path
      attr_reader :gitolite_repo_conf


      def initialize(repository, gitolite_config, action, opts = {})
        @repository         = repository
        @gitolite_config    = gitolite_config
        @action             = action
        @opts               = opts
        @project            = repository.project
        @notifier           = ::GitNotifier.new(repository)
        @gitolite_repo_name = repository.gitolite_repository_name
        @gitolite_repo_path = repository.gitolite_repository_path
        @gitolite_repo_conf = gitolite_config.repos[gitolite_repo_name]
        @old_perms          = {}
      end


      private


        def logger
          RedmineGitHosting.logger
        end


        def backup_old_perms
          @old_perms ||= PermissionsBuilder.get_permissions(gitolite_repo_conf)
        end


        def configuration_exists?
          !gitolite_repo_conf.nil?
        end


        def create_repository_config
          do_update_repository
        end


        def update_repository_config
          recreate_repository_config
        end


        def recreate_repository_config
          # Backup old perms
          backup_old_perms

          # Remove repo from Gitolite conf, we're gonna recreate it
          gitolite_config.rm_repo(gitolite_repo_name)

          # Recreate repository in Gitolite
          do_update_repository
        end


        def do_update_repository
          # Create Gitolite config
          repo_conf = create_gitolite_config

          # Add it to Gitolite
          gitolite_config.add_repo(repo_conf)

          # Update permissions
          set_repository_permissions(repo_conf)
        end


        def set_repository_permissions(repo_conf)
          repo_conf.permissions = PermissionsBuilder.new(repository, @old_perms).call
        end


        def create_gitolite_config
          # Create new repo object
          repo_conf = build_gitolite_repository

          # Set post-receive hook params
          repo_conf = set_default_conf(repo_conf)

          if project.active?
            # Set SmartHttp params
            repo_conf = set_smart_http_conf(repo_conf)

            # Set mail-notifications hook params
            repo_conf = set_mail_settings(repo_conf)

            # Set Git config keys
            repo_conf = set_repository_conf(repo_conf)
          else
            repo_conf.set_git_config("http.uploadpack", 'false')
            repo_conf.set_git_config("multimailhook.enabled", 'false')
          end

          # Return repository config
          repo_conf
        end


        def build_gitolite_repository
          ::Gitolite::Config::Repo.new(gitolite_repo_name)
        end


        def set_default_conf(repo_conf)
          repo_conf.set_git_config("redminegitolite.projectid", project.identifier.to_s)
          repo_conf.set_git_config("redminegitolite.repositoryid", "#{repository.identifier || ''}")
          repo_conf.set_git_config("redminegitolite.repositorykey", repository.extra[:key])
          repo_conf
        end


        def set_smart_http_conf(repo_conf)
          if User.anonymous.allowed_to?(:view_changesets, project) || repository.extra[:git_http] != 0
            repo_conf.set_git_config("http.uploadpack", 'true')
          else
            repo_conf.set_git_config("http.uploadpack", 'false')
          end
          repo_conf
        end


        def set_mail_settings(repo_conf)
          if repository.extra[:git_notify] && !notifier.mailing_list.empty?
            repo_conf.set_git_config("multimailhook.enabled", 'true')
            repo_conf.set_git_config("multimailhook.mailinglist", notifier.mailing_list.join(", "))
            repo_conf.set_git_config("multimailhook.from", notifier.sender_address)
            repo_conf.set_git_config("multimailhook.emailPrefix", notifier.email_prefix)
          else
            repo_conf.set_git_config("multimailhook.enabled", 'false')
          end
          repo_conf
        end


        def set_repository_conf(repo_conf)
          if repository.git_config_keys.any?
            repository.git_config_keys.each do |git_config_key|
              repo_conf.set_git_config(git_config_key.key, git_config_key.value)
            end
          end
          repo_conf
        end

    end
  end
end
