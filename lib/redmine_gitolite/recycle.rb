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
      @recycle_bin_dir     = RedmineGitolite::Config.gitolite_recycle_bin_dir
      @global_storage_dir  = RedmineGitolite::Config.gitolite_global_storage_dir
      @redmine_storage_dir = RedmineGitolite::Config.gitolite_redmine_storage_dir
      @recycle_bin_expiration_time = RedmineGitolite::Config.gitolite_recycle_bin_expiration_time
    end


    @@logger = nil
    def logger
      @@logger ||= RedmineGitolite::Log.get_logger(:recycle_bin)
    end


    def content
      return [] if !GitHosting.file_exists?(@recycle_bin_dir)
      return %x[#{GitHosting.shell_cmd_runner} find '#{@recycle_bin_dir}' -type d -regex '.*\.git' -prune -print].chomp.split("\n")
    end


    def move_repository_to_recycle(repository_data)
      repo_name = repository_data["repo_name"]
      repo_path = repository_data["repo_path"]

      # Only bother if actually exists!
      if !GitHosting.file_exists?(repo_path)
        logger.warn "Repository does not exist #{repo_path}"
        return false
      end

      trash_name = repo_name.gsub(/\//, TRASH_DIR_SEP)
      trash_path = File.join(@recycle_bin_dir, "#{Time.now.to_i.to_s}#{TRASH_DIR_SEP}#{trash_name}.git")

      logger.info "Moving '#{repo_name}' to Recycle Bin..."
      logger.debug "'#{repo_path}' => '#{trash_path}'"

      begin
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} mkdir -p '#{@recycle_bin_dir}']
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} chmod 770 '#{@recycle_bin_dir}']
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} mv '#{repo_path}' '#{trash_path}']
      rescue => e
        logger.error "Attempt to move repository '#{repo_path}' to Recycle Bin failed !"
        logger.error e.message
        return false
      end

      logger.info "Done !"
      logger.info "Will remain for at least #{@recycle_bin_expiration_time/60.0} hours"

      # If any empty directories left behind, try to delete them.  Ignore failure.
      # Top-level old directory without trailing '/'
      old_prefix = File.dirname(repo_name)

      if old_prefix
        repo_subpath    = File.join(@global_storage_dir, old_prefix, '/')
        redmine_storage = File.join(@global_storage_dir, @redmine_storage_dir)

        return false if repo_subpath == redmine_storage
        logger.info "Attempting to clean path '#{repo_subpath}'"
      end

      begin
        result = %x[#{GitHosting.shell_cmd_runner} find '#{repo_subpath}' -depth -type d ! -regex '.*\.git/.*' -empty -delete -print].chomp.split("\n")
        result.each { |dir| logger.info "Removing empty repository subdirectory : #{dir}" }
        return true
      rescue => e
        logger.error "Attempt to clean path '#{repo_subpath}' failed"
        logger.error e.message
        return false
      end
    end


    # Scan through the recyclebin and delete files older than 'preserve_time' minutes
    def delete_expired_files(repositories_array = [])
      return unless GitHosting.file_exists?(@recycle_bin_dir)

      if !repositories_array.empty?
        result = repositories_array
      else
        result = %x[#{GitHosting.shell_cmd_runner} find '#{@recycle_bin_dir}' -type d -regex '.*\.git' -cmin +#{@recycle_bin_expiration_time} -prune -print].chomp.split("\n")
      end

      if result.length > 0
        logger.info "Garbage-collecting expired '#{result.length}' file#{(result.length != 1) ? "s" : ""} from Recycle Bin :"
        result.each do |filename|
          logger.info "Deleting '#{filename}'"
          begin
            GitHosting.shell %[#{GitHosting.shell_cmd_runner} rm -rf #{filename}]
          rescue => e
            logger.error "GitoliteRecycle.delete_expired_files() failed trying to delete repository '#{filename}' !"
            logger.error e.message
          end
        end

        # Optionally remove recycle_bin (but only if empty).  Ignore error if non-empty
        %x[#{GitHosting.shell_cmd_runner} rmdir #{@recycle_bin_dir} 2>/dev/null]
      end
    end


    def recover_repository_if_present(repository)
      repo_name  = GitHosting.repository_name(repository)
      trash_name = "#{repo_name}".gsub(/\//,"#{TRASH_DIR_SEP}")

      myregex = File.join(@recycle_bin_dir, "[0-9]+#{TRASH_DIR_SEP}#{trash_name}.git")

      # Pull up any matching repositories. Sort them (beginning is representation of time)
      files = %x[#{GitHosting.shell_cmd_runner} find '#{@recycle_bin_dir}' -type d -regex '#{myregex}' -prune].chomp.split("\n").sort {|x, y| y <=> x }

      if files.length > 0
        # Found something!
        logger.info "Restoring '#{repo_name}.git' from Recycle Bin '#{files.first}'"

        begin
          # Complete directory path (if exists) without trailing '/'
          prefix = repo_name[/.*(?=\/)/]

          if prefix
            repo_prefix = File.join(@global_storage_dir, prefix)
            # Has subdirectory.  Must reconstruct directory
            GitHosting.shell %[#{GitHosting.shell_cmd_runner} mkdir -p '#{repo_prefix}']
          end

          repo_path = GitHosting.repository_path(repo_name)
          GitHosting.shell %[#{GitHosting.shell_cmd_runner} mv '#{files.first}' '#{repo_path}']

          # Optionally remove recycle_bin (but only if empty).  Ignore error if non-empty
          %x[#{GitHosting.shell_cmd_runner} rmdir #{@recycle_bin_dir} 2>/dev/null]

          return true
        rescue => e
          logger.error "Attempt to recover '#{repo_name}.git' from recycle bin failed"
          logger.error e.message
          return false
        end
      else
        return false
      end
    end

  end
end
