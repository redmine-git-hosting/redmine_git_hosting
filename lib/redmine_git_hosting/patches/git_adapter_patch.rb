module RedmineGitHosting
  module Patches
    module GitAdapterPatch

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          class << self
            alias_method_chain :sq_bin,         :git_hosting
            alias_method_chain :client_command, :git_hosting
          end

          alias_method_chain :git_cmd, :git_hosting
        end

      end


      module ClassMethods

        def sq_bin_with_git_hosting
          return Redmine::Scm::Adapters::GitAdapter::shell_quote(GitHosting.git_cmd_runner)
        end

        def client_command_with_git_hosting
          return GitHosting.git_cmd_runner
        end

      end


      module InstanceMethods

        private

        def git_cmd_with_git_hosting(args, options = {}, &block)
          repo_path = root_url || url
          full_args = [GitHosting.git_cmd_runner, '--git-dir', repo_path]
          if self.class.client_version_above?([1, 7, 2])
            full_args << '-c' << 'core.quotepath=false'
            full_args << '-c' << 'log.decorate=no'
          end
          full_args += args

          cmd_str = full_args.map { |e| shell_quote e.to_s }.join(' ')

          # Compute string from repo_path that should be same as: repo.git_label(:assume_unique=>false)
          # If only we had access to the repo (we don't).
          repo_id = Repository.repo_path_to_git_label(repo_path)

          # Insert cache between shell execution and caller
          # repo_path argument used to identify cache entries
          RedmineGitolite::Cache.execute(cmd_str, repo_id, options, &block)
        end

      end

    end
  end
end

unless Redmine::Scm::Adapters::GitAdapter.included_modules.include?(RedmineGitHosting::Patches::GitAdapterPatch)
  Redmine::Scm::Adapters::GitAdapter.send(:include, RedmineGitHosting::Patches::GitAdapterPatch)
end
