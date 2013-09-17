module GitHosting

  class GitoliteRecycle

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


    @@logger = nil
    def self.logger
      @@logger ||= GitoliteLogger.get_logger(:recycle_bin)
    end


    # This routine takes a name and turns it into a name for the recycle bit,
    # where we have a 1-level directory full of deleted repositories which
    # we keep for 'preserve_time'.
    def self.name_to_recycle_name repo_name
      new_trash_name = "#{repo_name}".gsub(/\//,"#{TRASH_DIR_SEP}")
    end


    # Scan through the recyclebin and delete files older than 'preserve_time' minutes
    def self.delete_expired_files
      return unless GitHosting.file_exists?(GitHostingConf.gitolite_recycle_bin_dir)

      result = %x[#{GitHosting.shell_cmd_runner} find '#{GitHostingConf.gitolite_recycle_bin_dir}' -type d -regex '.*\.git' -cmin +#{GitHostingConf.gitolite_recycle_bin_expiration_time} -prune -print].chomp.split("\n")
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
        %x[#{GitHosting.shell_cmd_runner} rmdir #{GitHostingConf.gitolite_recycle_bin_dir} 2>/dev/null]
      end
    end


    def self.move_repository_to_recycle repo_name
      # Only bother if actually exists!
      return unless GitHosting.git_repository_exists?(repo_name)

      repo_path = GitHosting.repository_path(repo_name)
      new_path = File.join(GitHostingConf.gitolite_recycle_bin_dir,"#{Time.now.to_i.to_s}#{TRASH_DIR_SEP}#{name_to_recycle_name(repo_name)}.git")

      logger.info "Moving '#{repo_name}' to Recycle Bin..."
      logger.debug "'#{repo_path}' => '#{new_path}'"

      begin
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} mkdir -p '#{GitHostingConf.gitolite_recycle_bin_dir}']
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} chmod 770 '#{GitHostingConf.gitolite_recycle_bin_dir}']
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} mv '#{repo_path}' '#{new_path}']
      rescue => e
        logger.error "Attempt to move repository '#{repo_path}' to Recycle Bin failed !"
        logger.error e.message
        return false
      end

      logger.info "Done !"
      logger.info "Will remain for at least #{GitHostingConf.gitolite_recycle_bin_expiration_time/60.0} hours"

      # If any empty directories left behind, try to delete them.  Ignore failure.
      old_prefix = repo_name[/.*?(?=\/)/] # Top-level old directory without trailing '/'
      if old_prefix
        repo_subpath = File.join(GitHostingConf.gitolite_global_storage_dir, old_prefix)
        begin
          result = %x[#{GitHosting.shell_cmd_runner} find '#{repo_subpath}' -depth -type d ! -regex '.*\.git/.*' -empty -delete -print].chomp.split("\n")
          result.each { |dir| logger.info "Removing empty repository subdirectory : #{dir}"}
          return true
        rescue => e
          logger.error "Attempt to clean path '#{repo_subpath}' failed"
          logger.error e.message
          return false
        end
      end
    end

    def self.recover_repository_if_present repo_name
      # Pull up any matching repositories.  Sort them (beginning is representation of time)
      myregex = File.join(GitHostingConf.gitolite_recycle_bin_dir, "[0-9]+#{TRASH_DIR_SEP}#{name_to_recycle_name(repo_name)}.git")
      files = %x[#{GitHosting.shell_cmd_runner} find '#{GitHostingConf.gitolite_recycle_bin_dir}' -type d -regex '#{myregex}' -prune].chomp.split("\n").sort {|x,y| y <=> x }
      if files.length > 0
        # Found something!
        logger.info "Restoring '#{repo_name}.git' from Recycle Bin '#{files.first}'"
        begin
          prefix = repo_name[/.*(?=\/)/] # Complete directory path (if exists) without trailing '/'
          if prefix
            repo_prefix = File.join(GitHostingConf.gitolite_global_storage_dir, prefix)
            # Has subdirectory.  Must reconstruct directory
            GitHosting.shell %[#{GitHosting.shell_cmd_runner} mkdir -p '#{repo_prefix}']
          end
          repo_path = GitHosting.repository_path(repo_name)
          GitHosting.shell %[#{GitHosting.shell_cmd_runner} mv '#{files.first}' '#{repo_path}']

          # Optionally remove recycle_bin (but only if empty).  Ignore error if non-empty
          %x[#{GitHosting.shell_cmd_runner} rmdir #{GitHostingConf.gitolite_recycle_bin_dir} 2>/dev/null]
          return true
        rescue => e
          logger.error "Attempt to recover '#{repo_name}.git' from recycle bin failed"
          logger.error e.message
          return false
        end
      else
        false
      end
    end

  end
end
