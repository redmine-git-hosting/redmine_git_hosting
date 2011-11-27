module GitHosting
	# This class implements a basic recycle bit for repositories deleted from the gitolite repository
	# 
	# Whenever repositories are deleted, we rename them and place them in the recycle_bin.
	# Assuming that GitoliteRecycle.delete_expired_files is called regularly, files in the recycle_bin
	# older than 'preserve_time' will be deleted.  Both the path for the recycle_bin and the preserve_time
  	# are settable as settings.
	#
	# John Kubiatowicz, 11/21/11
	class GitoliteRecycle
        	TRASH_DIR_SEP = "__"         	       # Separator character(s) used to replace '/' in name

                RECYCLE_BIN_IF_UNDEF = "recycle_bin/"  # In case settings not migrated (normally from settings)
                PRESERVE_TIME_IF_UNDEF = 1440          # In case settings not migrated (normally from settings)

        	def self.logger
			return GitHosting.logger
		end

                # Repository base path (relative to git user home directory)
                def self.repository_base
                	Setting.plugin_redmine_git_hosting['gitRepositoryBasePath']
                end

                # Recycle bin base path (relative to git user home directory)
                def self.recycle_bin
                	Setting.plugin_redmine_git_hosting['gitRecycleBasePath'] || RECYCLE_BIN_IF_UNDEF
                end

                # Recycle preservation time (in minutes)
                def self.preserve_time
                	(Setting.plugin_redmine_git_hosting['gitRecycleExpireTime'].to_f * 60).to_i || PRESERVE_TIME_IF_UNDEF
                end
                  
                # Scan through the recyclebin and delete files older than 'preserve_time' minutes
                # This can fail silently if, for instance, the recycle_bin doesn't exist.  That is the intended behavior.
          	def self.delete_expired_files
                	result = %x[#{GitHosting.git_user_runner} 'find #{recycle_bin} -type d -regex '.*\.git' -cmin +#{preserve_time} -prune -print'].chomp.split("\n")
                	if result.length > 0
                        	logger.warn "Garbage-collecting expired file#{(result.length != 1) ? "s" : ""} from recycle bin:"
                        	result.each do |filename| 
                			begin
                                        	GitHosting.shell %[#{GitHosting.git_user_runner} rm -r #{filename}]
						logger.warn "  Deleting #{filename}"
					rescue
                      				logger.error "GitoliteRecycle.delete_expired_files() failed trying to delete repository #{filename}!"
                       			end
                  		end

                        	# Optionally remove recycle_bin (but only if empty).  Ignore error if non-empty
                        	%x[#{GitHosting.git_user_runner} rmdir #{recycle_bin}]
                        end
                end

                def self.move_repository_to_recycle repo_name
                	repo_path = File.join(repository_base, repo_name)
                  	new_path = File.join(recycle_bin,"#{Time.now.to_i.to_s}#{TRASH_DIR_SEP}#{name_to_recycle_name(repo_name)}")                	
                	begin
                        	GitHosting.shell %[#{GitHosting.git_user_runner} mkdir -p '#{recycle_bin}']
                        	GitHosting.shell %[#{GitHosting.git_user_runner} mv '#{repo_path}.git' '#{new_path}.git']
                        	logger.warn "  Moving '#{repo_name}.git' from gitolite repository => '#{new_path}.git'.  Will remain for at least #{preserve_time/60.0} hours"
                          	# If any empty directories left behind, try to delete them.  Ignore failure.
                          	old_prefix = repo_name[/.*?(?=\/)/] # Top-level old directory without trailing '/'
                          	if old_prefix
                                  	repo_subpath = File.join(repository_base, old_prefix)
                                	result = %x[#{GitHosting.git_user_runner} find '#{repo_subpath}' -type d ! -regex '.*\.git/.*' -empty -depth -delete -print].chomp.split("\n")
                                	result.each { |dir| logger.warn "  Removing empty repository subdirectory: #{dir}"}
                                end
                        rescue
                        	logger.error "Attempt to move repository '#{repo_name}.git' to recycle bin failed"
                        end
                end

                def self.recover_repository_if_present repo_name
                	# Pull up any matching repositories.  Sort them (beginning is representation of time)
                  	myregex = File.join(recycle_bin,"[0-9]+#{TRASH_DIR_SEP}#{name_to_recycle_name(repo_name)}.git")
                  	files = %x[#{GitHosting.git_user_runner} find '#{recycle_bin}' -type d -regex '#{myregex}' -prune].chomp.split("\n").sort {|x,y| y <=> x }
                	if files.length > 0
                        	# Found something!
                          	logger.warn "Restoring '#{repo_name}.git' to gitolite repository from recycle bin (#{files.first})"
                        	begin
                                	prefix = repo_name[/.*(?=\/)/] # Complete directory path (if exists) without trailing '/'
                        		if prefix
                                        	repo_prefix = File.join(repository_base, prefix)
                                        	# Has subdirectory.  Must reconstruct directory
                                        	GitHosting.shell %[#{GitHosting.git_user_runner} mkdir -p '#{repo_prefix}']
                                        end
                                	repo_path = File.join(repository_base, repo_name)
                                	GitHosting.shell %[#{GitHosting.git_user_runner} mv '#{files.first}' '#{repo_path}.git']

                                	# Optionally remove recycle_bin (but only if empty).  Ignore error if non-empty
                        		%x[#{GitHosting.git_user_runner} rmdir #{recycle_bin}]
                                	return true
                                rescue
                                	logger.error "Attempt to recover '#{repo_name}.git' failed"
                                	return false
                                end
                        else
                        	false
                        end
                end

        	# This routine takes a name and turns it into a name for the recycle bit,
        	# where we have a 1-level directory full of deleted repositories which
        	# we keep for 'preserve_time'. 
		def self.name_to_recycle_name repo_name
                	new_trash_name = "#{repo_name}".gsub(/\//,"#{TRASH_DIR_SEP}")
                end


	end
end
