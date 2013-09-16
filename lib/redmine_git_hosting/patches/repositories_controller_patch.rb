module RedmineGitHosting
  module Patches
    module RepositoriesControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :show,     :git_hosting

          # RESTful (post-1.4).
          alias_method_chain :create,   :git_hosting rescue nil

          begin
            # RESTfull (post-1.4)
            alias_method_chain :update, :git_hosting
          rescue
            # Not RESTfull (pre-1.4)
            alias_method_chain :edit,   :git_hosting rescue nil
          end
        end
      end


      module InstanceMethods

        def show_with_git_hosting(&block)
          if @repository.is_a?(Repository::Git) and @rev.blank?
            # Fake list of repos
            @repositories = @project.all_repos
            render :action => 'git_instructions'
          else
            show_without_git_hosting(&block)
          end
        end


        # Post-1.4, all creation is done by create (rather than edit)
        def create_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)

          # Must create repository first
          create_without_git_hosting(&block)

          if !@repository.errors.any?
            # Update repository extras
            if request.post? && @repository && !params[:extra].nil?
              @repository.extra.update_attributes(params[:extra])
            end
            GitHostingObserver.set_update_active(@project)
          else
            GitHostingObserver.set_update_active(true)
          end
        end


        # This patch is only for pre-1.4 Redmine (since they made this controller RESTful
        def edit_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)

          params[:repository] ||= {}

          if params[:repository_scm] == "Git" && @project.repository
            params[:repository][:url] = GitHosting.repository_path(@project.repository)
          end

          if params[:repository_scm] == "Git" || @project.repository.is_a?(Repository::Git)
            # Evidently the ONLY way to update the repository.extra table is to basically copy/paste the existing controller code
            # the update line needs to go in the dead center of it.
            @repository = @project.repository
            if !@repository
              @repository = Repository.factory(params[:repository_scm])
              @repository.project = @project if @repository
            end
            if request.post? && @repository
              @repository.attributes = params[:repository]
              if !params[:extra].nil?
                @repository.extra.update_attributes(params[:extra])
              end
              @repository.save
            end

            render(:update) do |page|
              page.replace_html "tab-content-repository", :partial => 'projects/settings/repository'
              if @repository && !@project.repository
                @project.reload #needed to reload association
                page.replace_html "main-menu", render_main_menu(@project)
              end
            end

            if !@project.repository.nil?
              GitHostingObserver.bracketed_update_repositories(@project)
            end
          else
            edit_without_git_hosting(&block)
          end

          GitHostingObserver.set_update_active(true)
        end


        # Post-1.4, all of the updates are done by update (rather than edit with post)
        def update_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)

          update_without_git_hosting(&block)

          if !@repository.errors.any?
            # Update repository extras
            if request.put? && @repository && !params[:extra].nil?
              @repository.extra.update_attributes(params[:extra])
            end
            GitHostingObserver.set_update_active(@project)
          else
            GitHostingObserver.set_update_active(true)
          end
        end

      end

    end
  end
end

unless RepositoriesController.included_modules.include?(RedmineGitHosting::Patches::RepositoriesControllerPatch)
  RepositoriesController.send(:include, RedmineGitHosting::Patches::RepositoriesControllerPatch)
end
