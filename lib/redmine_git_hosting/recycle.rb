module RedmineGitHosting

  module Recycle

    # This module implements a basic recycle bit for repositories deleted from the gitolite repository
    #
    # Whenever repositories are deleted, we rename them and place them in the recycle_bin.
    # Assuming that GitoliteRecycle.delete_expired_files is called regularly, files in the recycle_bin
    # older than 'preserve_time' will be deleted.  Both the path for the recycle_bin and the preserve_time
    # are settable as settings.
    #
    # John Kubiatowicz, 11/21/11

    # Separator character(s) used to replace '/' in name
    TRASH_DIR_SEP = "__"


    class << self

      def gitolite_home_dir
        RedmineGitHosting::Config.gitolite_home_dir
      end


      def recycle_bin_dir
        @recycle_bin_dir ||= File.join(gitolite_home_dir, RedmineGitHosting::Config.gitolite_recycle_bin_dir)
      end


      def global_storage_dir
        @global_storage_dir ||= File.join(gitolite_home_dir, RedmineGitHosting::Config.gitolite_global_storage_dir)
      end


      def redmine_storage_dir
        @redmine_storage_dir ||= RedmineGitHosting::Config.gitolite_redmine_storage_dir
      end


      def recycle_bin_expiration_time
        @recycle_bin_expiration_time ||= RedmineGitHosting::Config.gitolite_recycle_bin_expiration_time
      end


      # Scan through the recyclebin and delete files older than 'preserve_time' minutes
      def delete_expired_files(repositories_array = [])
        logger.info("Nothing to do, exit !") && return if !directory_exists?(recycle_bin_dir)

        if !repositories_array.empty?
          result = repositories_array
        else
          begin
            result = get_expired_repositories
          rescue RedmineGitHosting::Error::GitoliteCommandException => e
            result = []
          end
        end

        if result.length > 0
          delete_old_directories(result)
        else
          logger.info("Nothing to do, exit !")
        end
      end


      def move_repository_to_recycle(repository_data)
        repo_name = repository_data[:repo_name]
        repo_path = File.join(gitolite_home_dir, repository_data[:repo_path])

        # Only bother if actually exists!
        if !directory_exists?(repo_path)
          logger.warn("Repository does not exist #{repo_path}")
          return false
        else
          do_move_repository_to_recycle(repository_data)
        end
      end


      def content
        return {} if !directory_exists?(recycle_bin_dir)

        begin
          directories = get_recycle_bin_content
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          directories = {}
        end

        if !directories.empty?
          return_value = get_directories_size(directories)
        else
          return_value = directories
        end

        return return_value
      end


      def recover_repository_if_present?(repository)
        repo_name = repository.gitolite_repository_name
        repo_path = File.join(gitolite_home_dir, repository.gitolite_repository_path)

        trash_name = "#{repo_name}".gsub(/\//, "#{TRASH_DIR_SEP}")

        myregex = File.join(recycle_bin_dir, "[0-9]+#{TRASH_DIR_SEP}#{trash_name}.git")

        # Pull up any matching repositories. Sort them (beginning is representation of time)
        begin
          files = find_old_repositories(myregex)
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          files = []
        end

        if files.length > 0
          # Found something!
          logger.info("Restoring '#{repo_name}.git'")

          begin
            # Complete directory path (if exists) without trailing '/'
            prefix = repo_name[/.*(?=\/)/]

            if prefix
              repo_prefix = File.join(global_storage_dir, redmine_storage_dir, prefix)

              logger.info("Create parent path : '#{repo_prefix}'")

              # Has subdirectory.  Must reconstruct directory
              RedmineGitHosting::Commands.sudo_mkdir_p(repo_prefix)
            end

            logger.info("Moving '#{files.first}' to '#{repo_path}'")

            RedmineGitHosting::Commands.sudo_move(files.first, repo_path)
            restored = true
          rescue RedmineGitHosting::Error::GitoliteCommandException => e
            logger.error("Attempt to recover '#{repo_name}.git' from recycle bin failed")
            restored = false
          end

          # Optionally remove recycle_bin (but only if empty).  Ignore error if non-empty
          delete_recycle_bin_dir

          return restored
        else
          return false
        end
      end


      private


        def logger
          RedmineGitHosting.logger
        end


        def directory_exists?(dir)
          RedmineGitHosting::Commands.sudo_dir_exists?(dir)
        end


        def delete_directory(dir, force = false)
          begin
            RedmineGitHosting::Commands.sudo_rmdir(dir, force)
            return true
          rescue RedmineGitHosting::Error::GitoliteCommandException => e
            return false
          end
        end


        def create_recycle_bin
          begin
            RedmineGitHosting::Commands.sudo_mkdir_p(recycle_bin_dir)
            RedmineGitHosting::Commands.sudo_chmod('770', recycle_bin_dir)
            return true
          rescue RedmineGitHosting::Error::GitoliteCommandException => e
            logger.error("Attempt to create recycle bin directory '#{recycle_bin_dir}' failed !")
            return false
          end
        end


        def delete_recycle_bin_dir
          delete_directory(recycle_bin_dir)
        end


        def repository_trash_path(repo_name)
          trash_name = repo_name.gsub(/\//, TRASH_DIR_SEP)
          File.join(recycle_bin_dir, "#{Time.now.to_i.to_s}#{TRASH_DIR_SEP}#{trash_name}.git")
        end


        def get_expired_repositories
          RedmineGitHosting::Commands.sudo_capture('find', recycle_bin_dir, '-type', 'd', '-regex', '.*\.git', '-cmin', "+#{recycle_bin_expiration_time}", '-prune', '-print').chomp.split("\n")
        end


        def get_recycle_bin_content
          RedmineGitHosting::Commands.sudo_capture('find', recycle_bin_dir, '-type', 'd', '-regex', '.*\.git', '-prune', '-print').chomp.split("\n")
        end


        def find_old_repositories(regex)
          RedmineGitHosting::Commands.sudo_capture('find', recycle_bin_dir, '-type', 'd', '-regex', regex, '-prune', '-print').chomp.split("\n").sort { |x, y| y <=> x }
        end


        def do_move_repository_to_recycle(repository_data)
          repo_name = repository_data[:repo_name]
          repo_path = File.join(gitolite_home_dir, repository_data[:repo_path])

          trash_path = repository_trash_path(repo_name)

          logger.info("Moving '#{repo_name}' to Recycle Bin...")
          logger.debug("'#{repo_path}' => '#{trash_path}'")

          if create_recycle_bin
            begin
              RedmineGitHosting::Commands.sudo_move(repo_path, trash_path)
            rescue RedmineGitHosting::Error::GitoliteCommandException => e
              logger.error("Attempt to move repository '#{repo_path}' to Recycle Bin failed !")
              return false
            end
          else
            return false
          end

          logger.info("Done !")
          logger.info("Will remain for at least #{recycle_bin_expiration_time / 60.0} hours")

          clean_path_tree(repo_name)

          return true
        end


        def delete_old_directories(directories)
          logger.info("Removing #{directories.length} expired repositor#{(directories.length != 1) ? "ies" : "y"} from Recycle Bin :")

          directories.each do |directory|
            logger.info("Deleting '#{directory}'")
            if delete_directory(directory, true)
              logger.info("Done !")
            else
              logger.error("GitoliteRecycle.delete_expired_files() failed trying to delete repository '#{directory}' !")
            end
          end

          # Optionally remove recycle_bin (but only if empty).  Ignore error if non-empty
          delete_recycle_bin_dir
        end


        def get_directories_size(directories)
          data = {}
          directories.sort.each { |dir| data[dir] = { size: RedmineGitHosting::Commands.sudo_get_dir_size(dir) } }
          data
        end


        def redmine_storage
          File.join(global_storage_dir, redmine_storage_dir)
        end


        def clean_path_tree(repo_name)
          # If any empty directories left behind, try to delete them.  Ignore failure.
          # Top-level old directory without trailing '/'
          old_prefix = File.dirname(repo_name)

          if old_prefix && old_prefix != '.'
            repo_subpath = File.join(global_storage_dir, old_prefix, '/')
            return if repo_subpath == redmine_storage || repo_subpath == ''
            logger.info("Attempting to clean path '#{repo_subpath}'")
          end

          logger.error("Attempt to clean path '#{repo_subpath}' failed") if !delete_directory(repo_subpath)
        end

    end

  end

end
