module RedmineGitolite

  class AdminRepositories < Admin

    include RedmineGitolite::AdminRepositoriesHelper


    def add_repository
      repository = Repository.find_by_id(@object_id)

      wrapped_transaction do

        handle_repository_add(repository)

        gitolite_admin_repo_commit("#{repository.gitolite_repository_name}")

        recycle = RedmineGitolite::Recycle.new

        if !recycle.recover_repository_if_present?(repository)
          logger.info { "#{@action} : let Gitolite create empty repository '#{repository.gitolite_repository_path}'" }
        else
          logger.info { "#{@action} : restored existing Gitolite repository '#{repository.gitolite_repository_path}' for update" }
        end
      end
    end


    def update_repository
      repository = Repository.find_by_id(@object_id)

      wrapped_transaction do
        handle_repository_update(repository)
        gitolite_admin_repo_commit("#{repository.gitolite_repository_name}")
      end
    end


    def delete_repositories
      repositories_array = @object_id

      wrapped_transaction do
        repositories_array.each do |repository_data|
          handle_repository_delete(repository_data)

          recycle = RedmineGitolite::Recycle.new
          recycle.move_repository_to_recycle(repository_data) if @delete_git_repositories

          gitolite_admin_repo_commit("#{repository_data['repo_name']}")
        end
      end
    end

  end
end
