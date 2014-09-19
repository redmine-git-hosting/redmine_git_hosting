require_dependency 'redmine/scm/adapters/git_adapter'

module RedmineGitHosting
  module Patches
    module GitAdapterPatch

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          class << self
            alias_method_chain :scm_version_from_command_line, :git_hosting
          end

          alias_method_chain :git_cmd, :git_hosting
        end

      end


      module ClassMethods

        def scm_version_from_command_line_with_git_hosting
          RedmineGitolite::GitoliteWrapper.sudo_capture('git', '--version', '--no-color')
        rescue => e
          RedmineGitolite::GitHosting.logger.error { "Can't retrieve git version: #{e.output}" }
          'unknown'
        end

      end


      module InstanceMethods

        private

        def git_cmd_with_git_hosting(args, options = {}, &block)
          repo_path = root_url || url

          full_args = []
          full_args << 'sudo'
          full_args += RedmineGitolite::GitoliteWrapper.sudo_shell_params
          full_args << 'git'
          full_args << '--git-dir'
          full_args << repo_path

          if self.class.client_version_above?([1, 7, 2])
            full_args << '-c' << 'core.quotepath=false'
            full_args << '-c' << 'log.decorate=no'
          end

          full_args += args

          cmd_str = full_args.map { |e| shell_quote e.to_s }.join(' ')

          # Compute string from repo_path that should be same as: repo.git_cache_id
          # If only we had access to the repo (we don't).
          RedmineGitolite::GitHosting.logger.debug { "Lookup for git_cache_id with repository path '#{repo_path}' ... " }

          git_cache_id = Repository::Git.repo_path_to_git_cache_id(repo_path)

          if !git_cache_id.nil?
            # Insert cache between shell execution and caller
            RedmineGitolite::GitHosting.logger.debug { "Found git_cache_id ('#{git_cache_id}'), call cache... " }
            RedmineGitolite::GitHosting.logger.debug { "Send GitCommand : #{cmd_str}" }
            RedmineGitolite::Cache.execute(cmd_str, git_cache_id, options, &block)
          else
            RedmineGitolite::GitHosting.logger.debug { "Unable to find git_cache_id, bypass cache... " }
            RedmineGitolite::GitHosting.logger.debug { "Send GitCommand : #{cmd_str}" }
            Redmine::Scm::Adapters::AbstractAdapter.shellout(cmd_str, options, &block)
          end
        end

      end

    end
  end
end

unless Redmine::Scm::Adapters::GitAdapter.included_modules.include?(RedmineGitHosting::Patches::GitAdapterPatch)
  Redmine::Scm::Adapters::GitAdapter.send(:include, RedmineGitHosting::Patches::GitAdapterPatch)
end
