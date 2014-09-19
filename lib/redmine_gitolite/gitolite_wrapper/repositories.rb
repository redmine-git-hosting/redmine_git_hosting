module RedmineGitolite

  module GitoliteWrapper

    class Repositories < Admin

      include RedmineGitolite::GitoliteWrapper::RepositoriesHelper


      def add_repository
        if repository = Repository.find_by_id(@object_id)

          if @options.has_key?(:create_readme_file) && (@options[:create_readme_file] == 'true' || @options[:create_readme_file] == true)
            create_readme = true
          else
            create_readme = false
          end

          @admin.transaction do

            handle_repository_add(repository)

            gitolite_admin_repo_commit("#{repository.gitolite_repository_name}")

            recycle = RedmineGitolite::Recycle.new

            @recovered = recycle.recover_repository_if_present?(repository)

            if !@recovered
              logger.info { "#{@action} : let Gitolite create empty repository '#{repository.gitolite_repository_path}'" }
            else
              logger.info { "#{@action} : restored existing Gitolite repository '#{repository.gitolite_repository_path}' for update" }
            end
          end

          if create_readme && !@recovered
            if RedmineGitolite::GitoliteWrapper.sudo_repository_empty?(repository.gitolite_repository_path)
              create_readme_file(repository)
            else
              logger.warn { "#{@action} : repository not empty, cannot create README file in path '#{repository.gitolite_repository_path}'" }
            end
          end

          repository.fetch_changesets
        else
          logger.error { "#{@action} : repository does not exist anymore, object is nil, exit !" }
        end
      end


      def update_repository
        if repository = Repository.find_by_id(@object_id)

          @admin.transaction do
            handle_repository_update(repository)
            gitolite_admin_repo_commit("#{repository.gitolite_repository_name}")
          end

          # Treat options
          if @options.has_key?(:delete_git_config_key) && !@options[:delete_git_config_key].empty?
            delete_hook_param(repository, @options[:delete_git_config_key])
          end
        else
          logger.error { "#{@action} : repository does not exist anymore, object is nil, exit !" }
        end
      end


      def delete_repositories
        repositories_array = @object_id

        @admin.transaction do
          repositories_array.each do |repository_data|
            handle_repository_delete(repository_data)

            recycle = RedmineGitolite::Recycle.new
            recycle.move_repository_to_recycle(repository_data) if RedmineGitolite::Config.get_setting(:delete_git_repositories, true)

            gitolite_admin_repo_commit("#{repository_data['repo_name']}")
          end
        end
      end


      def update_repository_default_branch
        if repository = Repository.find_by_id(@object_id)

          begin
            RedmineGitolite::GitoliteWrapper.sudo_capture('git', "--git-dir=#{repository.gitolite_repository_path}", 'symbolic-ref', 'HEAD', "refs/heads/#{repository.extra[:default_branch]}")
            logger.info { "Default branch successfully updated for repository '#{repository.gitolite_repository_name}'" }
          rescue RedmineGitolite::GitHosting::GitHostingException => e
            logger.error { "Error while updating default branch for repository '#{repository.gitolite_repository_name}'" }
          end

          RedmineGitolite::Cache.clear_cache_for_repository(repository)

          logger.info { "Fetch changesets for repository '#{repository.gitolite_repository_name}'"}
          repository.fetch_changesets
        else
          logger.error { "#{@action} : repository does not exist anymore, object is nil, exit !" }
        end
      end

    end
  end
end
