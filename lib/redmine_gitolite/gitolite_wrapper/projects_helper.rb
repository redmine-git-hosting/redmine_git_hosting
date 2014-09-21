module RedmineGitolite

  module GitoliteWrapper

    module ProjectsHelper


      def handle_repositories_move(git_projects)
        git_projects.reverse.each do |project|
          repo_list = []

          project.gitolite_repos.reverse.each do |repository|
            repo_list.push(repository.gitolite_repository_name)
            perform_repository_move(repository)
          end

          gitolite_admin_repo_commit("#{action} : #{project.identifier} | #{repo_list}")
        end
      end


      def perform_repository_move(repository)
        repo_id   = repository.redmine_name
        repo_name = repository.old_repository_name

        repo_conf = gitolite_config.repos[repo_name]

        old_repo_name = repository.old_repository_name
        new_repo_name = repository.new_repository_name

        old_relative_path  = repository.url
        new_relative_path  = repository.gitolite_repository_path

        old_relative_parent_path = old_relative_path.gsub(repo_id + '.git', '')
        new_relative_parent_path = new_relative_path.gsub(repo_id + '.git', '')

        logger.info { "#{action} : Moving '#{repo_name}'..." }
        logger.debug { "  Old repository name (for Gitolite)           : #{old_repo_name}" }
        logger.debug { "  New repository name (for Gitolite)           : #{new_repo_name}" }
        logger.debug { "-----" }
        logger.debug { "  Old relative path (for Redmine code browser) : #{old_relative_path}" }
        logger.debug { "  New relative path (for Redmine code browser) : #{new_relative_path}" }
        logger.debug { "-----" }
        logger.debug { "  Old relative parent path (for Gitolite)      : #{old_relative_parent_path}" }
        logger.debug { "  New relative parent path (for Gitolite)      : #{new_relative_parent_path}" }

        if !repo_conf
          logger.error { "#{action} : repository '#{repo_name}' does not exist in Gitolite, exit !" }
          return
        else
          if move_physical_repo(old_relative_path, new_relative_path, new_relative_parent_path)
            @delete_parent_path.push(old_relative_parent_path)

            repository.update_column(:url, new_relative_path)
            repository.update_column(:root_url, new_relative_path)

            # update gitolite conf
            old_perms = get_old_permissions(repo_conf)
            gitolite_config.rm_repo(old_repo_name)
            handle_repository_add(repository, :force => true, :old_perms => old_perms)
          else
            return false
          end
        end
      end


      def move_physical_repo(old_path, new_path, new_parent_path)
        ## CASE 0
        if old_path == new_path
          logger.info { "#{action} : old repository and new repository are identical '#{old_path}', nothing to do, exit !" }
          return true
        end

        # Now we have multiple options, due to the way gitolite sets up repositories
        new_path_exists = GitoliteWrapper.sudo_dir_exists?(new_path)
        old_path_exists = GitoliteWrapper.sudo_dir_exists?(old_path)

        ## CASE 1
        if new_path_exists && old_path_exists

          if GitoliteWrapper.sudo_repository_empty?(new_path)
            logger.warn { "#{action} : target repository '#{new_path}' already exists and is empty, remove it ..." }
            begin
              GitoliteWrapper.sudo_rmdir(new_path, true)
            rescue GitHosting::GitHostingException => e
              logger.error { "#{action} : removing existing target repository failed, exit !" }
              return false
            end
          else
            logger.warn { "#{action} : target repository '#{new_path}' exists and is not empty, considered as already moved, try to remove the old_path if empty" }

            if GitoliteWrapper.sudo_repository_empty?(old_path)
              begin
                GitoliteWrapper.sudo_rmdir(old_path, true)
                return true
              rescue GitHosting::GitHostingException => e
                logger.error { "#{action} : removing source repository directory failed, exit !" }
                return false
              end
            else
              logger.error { "#{action} : the source repository directory is not empty, cannot remove it, exit ! (This repo will be orphan)" }
              return false
            end
          end

        ## CASE 2
        elsif !new_path_exists && old_path_exists

          logger.debug { "#{action} : really moving Gitolite repository from '#{old_path}' to '#{new_path}'" }

          if !GitoliteWrapper.sudo_dir_exists?(new_parent_path)
            begin
              GitoliteWrapper.sudo_mkdir('-p', new_parent_path)
            rescue GitHosting::GitHostingException => e
              logger.error { "#{action} : creation of parent path '#{new_parent_path}' failed, exit !" }
              return false
            end
          end

          begin
            GitoliteWrapper.sudo_move(old_path, new_path)
            logger.info { "#{action} : done !" }
            return true
          rescue GitHosting::GitHostingException => e
            logger.error { "move_physical_repo(#{old_path}, #{new_path}) failed" }
            return false
          end

        ## CASE 3
        elsif !new_path_exists && !old_path_exists
          logger.error { "#{action} : both old repository '#{old_path}' and new repository '#{new_path}' does not exist, cannot move it, exit but let Gitolite create the new repo !" }
          return true

        ## CASE 4
        elsif new_path_exists && !old_path_exists
          logger.error { "#{action} : old repository '#{old_path}' does not exist, but the new one does, use it !" }
          return true

        end
      end


      def clean_path(path_list)
        path_list.uniq.sort.reverse.each do |path|
          begin
            logger.info { "#{action} : cleaning repository path : '#{path}'" }
            GitoliteWrapper.sudo_rmdir(path)
          rescue GitHosting::GitHostingException => e
            logger.error { "#{action} : error while cleaning repository path '#{path}'" }
          end
        end
      end

    end
  end
end
