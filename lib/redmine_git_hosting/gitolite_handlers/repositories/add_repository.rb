# frozen_string_literal: true

module RedmineGitHosting
  module GitoliteHandlers
    module Repositories
      class AddRepository < Base
        def call
          if !configuration_exists?
            # Create repository in Gitolite
            log_repo_not_exist 'create it ...'
            create_repository_config

          elsif configuration_exists? && force
            # Recreate repository in Gitolite
            log_repo_already_exist 'force mode !'
            recreate_repository_config

          else
            log_repo_already_exist 'exit !'
          end
        end

        def gitolite_repo_name
          repository.gitolite_repository_name
        end

        def gitolite_repo_path
          repository.gitolite_repository_path
        end

        attr_reader :force

        def initialize(gitolite_config, repository, context, **options)
          super(gitolite_config, repository, context, **options)
          @force     = options.delete(:force) { false }
          @old_perms = options.delete(:old_perms) { {} }
        end
      end
    end
  end
end
