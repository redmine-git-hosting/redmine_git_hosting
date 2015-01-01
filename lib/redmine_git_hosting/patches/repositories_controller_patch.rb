require_dependency 'repositories_controller'

module RedmineGitHosting
  module Patches
    module RepositoriesControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :show,    :git_hosting
          alias_method_chain :create,  :git_hosting
          alias_method_chain :update,  :git_hosting
          alias_method_chain :destroy, :git_hosting

          before_filter :set_current_tab, only: :edit

          helper :git_hosting

          # Load ExtendRepositoriesHelper so we can call our
          # additional methods.
          helper :extend_repositories
        end
      end


      module InstanceMethods

        def show_with_git_hosting(&block)
          if @repository.is_a?(Repository::Xitolite) && @repository.empty?
            # Fake list of repos
            @repositories = @project.gitolite_repos
            render 'git_instructions'
          else
            show_without_git_hosting(&block)
          end
        end


        def create_with_git_hosting(&block)
          create_without_git_hosting(&block)
          call_use_cases
        end


        def update_with_git_hosting(&block)
          update_without_git_hosting(&block)
          call_use_cases
        end


        def destroy_with_git_hosting(&block)
          destroy_without_git_hosting(&block)
          call_use_cases
        end


        private


          def set_current_tab
            @tab = params[:tab] || ""
          end


          def call_use_cases
            if @repository.is_a?(Repository::Xitolite)
              if !@repository.errors.any?
                case self.action_name
                when 'create'
                  CreateRepository.new(@repository, creation_options).call
                when 'update'
                  UpdateRepository.new(@repository).call
                when 'destroy'
                  DestroyRepository.new(@repository).call
                end
              end
            end
          end


          def creation_options
            {create_readme_file: create_readme_file?, enable_git_annex: enable_git_annex?}
          end


          def create_readme_file?
            @repository.create_readme == 'true' ? true : false
          end


          def enable_git_annex?
            @repository.enable_git_annex == 'true' ? true : false
          end

      end

    end
  end
end

unless RepositoriesController.included_modules.include?(RedmineGitHosting::Patches::RepositoriesControllerPatch)
  RepositoriesController.send(:include, RedmineGitHosting::Patches::RepositoriesControllerPatch)
end
