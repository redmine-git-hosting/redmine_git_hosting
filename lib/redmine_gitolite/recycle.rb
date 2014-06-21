module RedmineGitolite

  class Recycle

    # This class implements a basic recycle bit for repositories deleted from the gitolite repository
    #
    # Whenever repositories are deleted, we rename them and place them in the recycle_bin.
    # Assuming that GitoliteRecycle.delete_expired_files is called regularly, files in the recycle_bin
    # older than 'preserve_time' will be deleted.  Both the path for the recycle_bin and the preserve_time
    # are settable as settings.
    #
    # John Kubiatowicz, 11/21/11

    # Separator character(s) used to replace '/' in name
    TRASH_DIR_SEP = "__"


    def initialize
      @recycle_bin_dir     = RedmineGitolite::Config.get_setting(:gitolite_recycle_bin_dir)
      @global_storage_dir  = RedmineGitolite::Config.get_setting(:gitolite_global_storage_dir)
      @redmine_storage_dir = RedmineGitolite::Config.get_setting(:gitolite_redmine_storage_dir)
      @recycle_bin_expiration_time = (RedmineGitolite::Config.get_setting(:gitolite_recycle_bin_expiration_time).to_f*60).to_i

      @gitolite_home_dir   = set_gitolite_home_dir
    end


    def content
      return {} if !dir_exists?(@recycle_bin_dir)

      begin
        directories = RedmineGitolite::GitoliteWrapper.sudo_capture('find', @recycle_bin_dir, '-type', 'd', '-regex', '.*\.git', '-prune', '-print').chomp.split("\n")
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        directories = {}
      end

      if !directories.empty?
        return_value = get_directories_size(directories)
      else
        return_value = directories
      end

      return return_value
    end


    # Scan through the recyclebin and delete files older than 'preserve_time' minutes
    def delete_expired_files(repositories_array = [])
      return unless dir_exists?(@recycle_bin_dir)

      if !repositories_array.empty?
        result = repositories_array
      else
        begin
          result = RedmineGitolite::GitoliteWrapper.sudo_capture('find', @recycle_bin_dir, '-type', 'd', '-regex', '.*\.git', '-cmin', "+#{@recycle_bin_expiration_time}", '-prune', '-print').chomp.split("\n")
        rescue => e
          result = []
        end
      end

      if result.length > 0
        logger.info { "Garbage-collecting #{result.length} expired repositor#{(result.length != 1) ? "ies" : "y"} from Recycle Bin :" }

        result.each do |dirname|
          path = File.join(@gitolite_home_dir, dirname)
          logger.info { "Deleting '#{path}'" }
          begin
            RedmineGitolite::GitoliteWrapper.sudo_rmdir(path, true)
          rescue RedmineGitolite::GitHosting::GitHostingException => e
            logger.error { "GitoliteRecycle.delete_expired_files() failed trying to delete repository '#{path}' !" }
          end
        end

        # Optionally remove recycle_bin (but only if empty).  Ignore error if non-empty
        delete_recycle_bin_dir

        return
      else
        logger.info { "Nothing to do, exit !" }
      end
    end


    def move_repository_to_recycle(repository_data)
      repo_name = repository_data["repo_name"]
      repo_path = repository_data["repo_path"]

      # Only bother if actually exists!
      if !dir_exists?(repo_path)
        logger.warn { "Repository does not exist #{repo_path}" }
        return false
      end

      trash_name = repo_name.gsub(/\//, TRASH_DIR_SEP)
      trash_path = File.join(@recycle_bin_dir, "#{Time.now.to_i.to_s}#{TRASH_DIR_SEP}#{trash_name}.git")

      logger.info { "Moving '#{repo_name}' to Recycle Bin..." }
      logger.debug { "'#{repo_path}' => '#{trash_path}'" }

      if create_recycle_bin
        begin
          RedmineGitolite::GitoliteWrapper.sudo_move(repo_path, trash_path)
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Attempt to move repository '#{repo_path}' to Recycle Bin failed !" }
          return false
        end
      else
        return false
      end

      logger.info { "Done !" }
      logger.info { "Will remain for at least #{@recycle_bin_expiration_time/60.0} hours" }

      clean_path_tree(repo_name)

      return true
    end


    def recover_repository_if_present?(repository)
      repo_name = repository.gitolite_repository_name
      repo_path = repository.gitolite_repository_path

      trash_name = "#{repo_name}".gsub(/\//, "#{TRASH_DIR_SEP}")

      myregex = File.join(@recycle_bin_dir, "[0-9]+#{TRASH_DIR_SEP}#{trash_name}.git")

      # Pull up any matching repositories. Sort them (beginning is representation of time)
      begin
        files = RedmineGitolite::GitoliteWrapper.sudo_capture('find', @recycle_bin_dir, '-type', 'd', '-regex', myregex, '-prune', '-print').chomp.split("\n").sort {|x, y| y <=> x }
      rescue Exception => e
        files = []
      end

      if files.length > 0
        # Found something!
        logger.info { "Restoring '#{repo_name}.git'" }

        begin
          # Complete directory path (if exists) without trailing '/'
          prefix = repo_name[/.*(?=\/)/]

          if prefix
            repo_prefix = File.join(@global_storage_dir, prefix)
            # Has subdirectory.  Must reconstruct directory
            RedmineGitolite::GitoliteWrapper.sudo_mkdir('-p', repo_prefix)
          end

          logger.info { "Moving '#{files.first}' to '#{repo_path}'" }

          RedmineGitolite::GitoliteWrapper.sudo_move(files.first, repo_path)
          restored = true
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Attempt to recover '#{repo_name}.git' from recycle bin failed" }
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
      RedmineGitolite::Log.get_logger(:recycle_bin)
    end


    def set_gitolite_home_dir
      begin
        RedmineGitolite::GitoliteWrapper.gitolite_home_dir
      rescue => e
        '$HOME'
      end
    end


    def dir_exists?(dir_path)
      RedmineGitolite::GitoliteWrapper.sudo_dir_exists?(dir_path)
    end


    def create_recycle_bin
      begin
        RedmineGitolite::GitoliteWrapper.sudo_mkdir('-p', @recycle_bin_dir)
        RedmineGitolite::GitoliteWrapper.sudo_chmod('770', @recycle_bin_dir)
        return true
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        logger.error { "Attempt to create recycle bin directory '#{@recycle_bin_dir}' failed !" }
        return false
      end
    end


    def delete_recycle_bin_dir
      begin
        RedmineGitolite::GitoliteWrapper.sudo_rmdir(@recycle_bin_dir)
        return true
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        return false
      end
    end


    def clean_path_tree(repo_name)
      # If any empty directories left behind, try to delete them.  Ignore failure.
      # Top-level old directory without trailing '/'
      old_prefix = File.dirname(repo_name)

      if old_prefix && old_prefix != '.'
        repo_subpath    = File.join(@global_storage_dir, old_prefix, '/')
        redmine_storage = File.join(@global_storage_dir, @redmine_storage_dir)

        return if repo_subpath == redmine_storage || repo_subpath == ''
        logger.info { "Attempting to clean path '#{repo_subpath}'" }
      end

      begin
        RedmineGitolite::GitoliteWrapper.sudo_rmdir(repo_subpath)
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        logger.error { "Attempt to clean path '#{repo_subpath}' failed" }
      end
    end


    def get_directories_size(directories)
      data = {}
      directories.sort.each do |directory|
        data[directory] = { :size => (RedmineGitolite::GitoliteWrapper.sudo_capture('du', '-sh', directory).split(" ")[0] rescue '') }
      end
      return data
    end

  end
end
