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

          before_filter :set_current_tab, :only => :edit

          helper :git_hosting
        end
      end

      module InstanceMethods

        def show_with_git_hosting(&block)
          if @repository.is_a?(Repository::Gitolite) && @repository.empty?
            # Fake list of repos
            @repositories = @project.gitolite_repos
            render :action => 'git_instructions'
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
            if @repository.is_a?(Repository::Gitolite)
              if !@repository.errors.any?
                case self.action_name
                when 'create'
                  CreateRepository.new(@repository, params).call
                when 'update'
                  UpdateRepository.new(@repository, params).call
                when 'destroy'
                  DestroyRepository.new(@repository).call
                end
              end
            end
          end

      end

    end
  end
end

unless RepositoriesController.included_modules.include?(RedmineGitHosting::Patches::RepositoriesControllerPatch)
  RepositoriesController.send(:include, RedmineGitHosting::Patches::RepositoriesControllerPatch)
end
