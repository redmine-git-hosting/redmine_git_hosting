module RedmineGitHosting
  module GitoliteHandlers
    module Repositories
      class Base

        attr_reader :gitolite_config
        attr_reader :repository
        attr_reader :context
        attr_reader :options


        def initialize(gitolite_config, repository, context, options = {})
          @gitolite_config    = gitolite_config
          @repository         = repository
          @context            = context
          @options            = options.dup
          @old_perms          = {}
        end

        class << self

          def call(gitolite_config, repository, context, options = {})
            new(gitolite_config, repository, context, options).call
          end

        end


        def call
          raise NotImplementedError
        end


        private


          def logger
            RedmineGitHosting.logger
          end


          def backup_old_perms
            @old_perms = repository.backup_gitolite_permissions(gitolite_repo_conf.permissions[0])
          end


          def configuration_exists?
            !gitolite_repo_conf.nil?
          end


          def gitolite_repo_conf
            gitolite_config.repos[gitolite_repo_name]
          end


          def create_repository_config
            # Create Gitolite config
            repo_conf = build_repository_config

            # Update permissions
            repo_conf.permissions = repository.build_gitolite_permissions(@old_perms)

            # Add it to Gitolite
            gitolite_config.add_repo(repo_conf)

            # Return repository conf
            repo_conf
          end


          def update_repository_config
            recreate_repository_config
          end


          def delete_repository_config
            gitolite_config.rm_repo(gitolite_repo_name)
          end


          def recreate_repository_config
            # Backup old perms
            backup_old_perms

            # Remove repo from Gitolite conf, we're gonna recreate it
            delete_repository_config

            # Recreate repository in Gitolite
            create_repository_config
          end


          def build_repository_config
            repo_conf = ::Gitolite::Config::Repo.new(repository.gitolite_repository_name)

            repository.git_config.each do |key, value|
              repo_conf.set_git_config(key, value)
            end

            repository.gitolite_options.each do |key, value|
              repo_conf.set_gitolite_option(key, value)
            end

            repo_conf
          end


          def log_ok_and_continue(message)
            logger.info("#{context} : repository '#{gitolite_repo_name}' exists in Gitolite, #{message}")
            logger.debug("#{context} : repository path '#{gitolite_repo_path}'")
          end


          def log_repo_not_exist(message)
            logger.warn("#{context} : repository '#{gitolite_repo_name}' does not exist in Gitolite, #{message}")
            logger.debug("#{context} : repository path '#{gitolite_repo_path}'")
          end


          def log_repo_already_exist(message)
            logger.warn("#{context} : repository '#{gitolite_repo_name}' already exists in Gitolite, #{message}")
            logger.debug("#{context} : repository path '#{gitolite_repo_path}'")
          end

      end
    end
  end
end
