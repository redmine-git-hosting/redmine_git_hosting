# frozen_string_literal: true

module RedmineGitHosting
  module GitoliteWrappers
    class Base
      include RedmineGitHosting::GitoliteAccessor::Methods

      attr_reader :admin, :object_id, :options, :gitolite_config

      def initialize(admin, object_id, **options)
        @admin           = admin
        @object_id       = object_id
        @options         = options
        @gitolite_config = admin.config
      end

      class << self
        def call(admin, object_id, **options)
          new(admin, object_id, **options).call
        end

        def inherited(klass)
          @wrappers ||= {}
          @wrappers[klass.name.demodulize.underscore.to_sym] = klass
        end

        def wrappers
          @wrappers ||= {}
        end

        def for_action(action)
          unless wrappers.key? action
            raise RedmineGitHosting::Error::GitoliteWrapperException, "No available Wrapper for action '#{action}' found."
          end

          wrappers[action]
        end
      end

      def call
        raise NotImplementedError
      end

      def gitolite_admin_repo_commit(message = '')
        logger.info "#{context} : commiting to Gitolite..."
        admin.save "#{context} : #{message}"
      rescue StandardError => e
        logger.error e.message
      end

      def create_gitolite_repository(repository)
        GitoliteHandlers::Repositories::AddRepository.call gitolite_config, repository, context, **options
      end

      def update_gitolite_repository(repository)
        GitoliteHandlers::Repositories::UpdateRepository.call gitolite_config, repository, context, **options
      end

      def delete_gitolite_repository(repository)
        GitoliteHandlers::Repositories::DeleteRepository.call gitolite_config, repository, context, **options
      end

      def move_gitolite_repository(repository)
        GitoliteHandlers::Repositories::MoveRepository.call gitolite_config, repository, context, **options
      end

      def create_gitolite_key(key)
        GitoliteHandlers::SshKeys::AddSshKey.call admin, key, context
      end

      def delete_gitolite_key(key)
        GitoliteHandlers::SshKeys::DeleteSshKey.call admin, key, context
      end

      private

      def context
        self.class.name.demodulize.underscore
      end

      def logger
        RedmineGitHosting.logger
      end

      def log_object_dont_exist
        logger.error "#{context} : repository does not exist anymore, object is nil, exit !"
      end
    end
  end
end
