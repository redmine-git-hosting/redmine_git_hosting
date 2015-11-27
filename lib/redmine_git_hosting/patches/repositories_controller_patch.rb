require_dependency 'repositories_controller'

module RedmineGitHosting
  module Patches
    module RepositoriesControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, RedmineGitHosting::GitoliteAccessor::Methods)
        base.class_eval do
          alias_method_chain :show,    :git_hosting
          alias_method_chain :create,  :git_hosting
          alias_method_chain :update,  :git_hosting
          alias_method_chain :destroy, :git_hosting
          alias_method_chain :diff,    :git_hosting

          alias_method_chain :find_project_repository, :git_hosting

          before_filter :set_current_tab, only: :edit

          helper :redmine_bootstrap_kit
          helper :watchers

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


        # Monkey patch *diff* method to pass the *bypass_cache* flag
        # on diff download.
        #
        def diff_with_git_hosting(&block)
          if @repository.is_a?(Repository::Xitolite)
            diff_with_options
          else
            diff_without_git_hosting(&block)
          end
        end


        private


          def set_current_tab
            @tab = params[:tab] || ''
          end


          def call_use_cases
            if @repository.is_a?(Repository::Xitolite)
              if !@repository.errors.any?
                case self.action_name
                when 'create'
                  # Call UseCase object that will complete Repository creation :
                  # it will create GitExtra association and then the repository in Gitolite.
                  Repositories::Create.call(@repository, creation_options)
                when 'update'
                  gitolite_accessor.update_repository(@repository)
                when 'destroy'
                  gitolite_accessor.destroy_repository(@repository)
                end
              end
            end
          end


          def creation_options
            { create_readme_file: create_readme_file?, enable_git_annex: enable_git_annex? }
          end


          def create_readme_file?
            @repository.create_readme == 'true' ? true : false
          end


          def enable_git_annex?
            @repository.enable_git_annex == 'true' ? true : false
          end


          REV_PARAM_RE = %r{\A[a-f0-9]*\Z}i

          # Monkey patch *find_project_repository* method to render Git instructions
          # if repository has no branch
          #
          def find_project_repository_with_git_hosting
            @project = Project.find(params[:id])
            if params[:repository_id].present?
              @repository = @project.repositories.find_by_identifier_param(params[:repository_id])
            else
              @repository = @project.repository
            end
            (render_404; return false) unless @repository
            @path = params[:path].is_a?(Array) ? params[:path].join('/') : params[:path].to_s
            @rev = params[:rev].blank? ? @repository.default_branch : params[:rev].to_s.strip
            @rev_to = params[:rev_to]

            unless @rev.to_s.match(REV_PARAM_RE) && @rev_to.to_s.match(REV_PARAM_RE)
              raise InvalidRevisionParam if @repository.branches.empty?
            end
          rescue ActiveRecord::RecordNotFound
            render_404
          rescue InvalidRevisionParam
            # Fake list of repos
            @repositories = @project.gitolite_repos
            render 'git_instructions'
          end


          # This is the original diff method with the *bypass_cache* flag
          # for diff download. We keep the cache for the diff view.
          #
          def diff_with_options
            if params[:format] == 'diff'
              @diff = @repository.diff(@path, @rev, @rev_to, bypass_cache: true)
              (show_error_not_found; return) unless @diff
              filename = "changeset_r#{@rev}"
              filename << "_r#{@rev_to}" if @rev_to
              send_data @diff.join, :filename => "#{filename}.diff",
                                    :type => 'text/x-patch',
                                    :disposition => 'attachment'
            else
              @diff_type = params[:type] || User.current.pref[:diff_type] || 'inline'
              @diff_type = 'inline' unless %w(inline sbs).include?(@diff_type)

              # Save diff type as user preference
              if User.current.logged? && @diff_type != User.current.pref[:diff_type]
                User.current.pref[:diff_type] = @diff_type
                User.current.preference.save
              end
              @cache_key = "repositories/diff/#{@repository.id}/" +
                              Digest::MD5.hexdigest("#{@path}-#{@rev}-#{@rev_to}-#{@diff_type}-#{current_language}")
              unless read_fragment(@cache_key)
                @diff = @repository.diff(@path, @rev, @rev_to)
                show_error_not_found unless @diff
              end

              @changeset = @repository.find_changeset_by_name(@rev)
              @changeset_to = @rev_to ? @repository.find_changeset_by_name(@rev_to) : nil
              @diff_format_revisions = @repository.diff_format_revisions(@changeset, @changeset_to)
            end
          end

      end

    end
  end
end

unless RepositoriesController.included_modules.include?(RedmineGitHosting::Patches::RepositoriesControllerPatch)
  RepositoriesController.send(:include, RedmineGitHosting::Patches::RepositoriesControllerPatch)
end
