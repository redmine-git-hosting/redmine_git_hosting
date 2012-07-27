require_dependency 'principal'
require_dependency 'user'
require_dependency 'git_hosting'
require_dependency 'repository'

module GitHosting
	module Patches
		module RepositoryPatch
			module ClassMethods
				def fetch_changesets_for_project(proj_identifier)
					p = Project.find_by_identifier(proj_identifier)
					if p
						if p.repository
							begin
								p.repository.fetch_changesets
							rescue Redmine::Scm::Adapters::CommandFailed => e
								logger.error "scm: error during fetching changesets: #{e.message}"
							end
						end
					end
				end

				def factory_with_git_extra_init(klass_name, *args)
					new_repo = factory_without_git_extra_init(klass_name, *args)
					if new_repo.is_a?(Repository::Git)
						if new_repo.extra.nil?
							# Note that this autoinitializes default values and hook key
							GitHosting.logger.error "Automatic initialization of git_repository_extra failed for #{self.project.to_s}"
						end
					end
					return new_repo
				end
				def fetch_changesets_with_disable_update
					# Turn of updates during repository update
					GitHostingObserver.set_update_active(false);

					# Do actual update
					fetch_changesets_without_disable_update

					# Reenable updates to perform a sync of all projects
					GitHostingObserver.set_update_active(:resync_all);
				end
			end

			module InstanceMethods
				# New version of extra() -- construct extra association if missing
				def extra
					retval = self.git_extra
					if retval.nil?
						# Construct new extra structure, followed by updating hooks (if necessary)
						GitHostingObserver.set_update_active(false);

						retval = GitRepositoryExtra.new()
						self.git_extra = retval	 # Should save object...

						# If self.project != nil, trigger repair of hooks
						GitHostingObserver.set_update_active(true, self.project, :resync_hooks => true)
					end
					retval
				end

				def extra=(new_extra_struct)
					self.git_extra=(new_extra_struct)
				end
			end


			def self.included(base)
				base.class_eval do
					unloadable

					extend(ClassMethods)
					class << self
						alias_method_chain :factory, :git_extra_init
						alias_method_chain :fetch_changesets, :disable_update
					end

					# initialize association from git repository -> git_extra
					has_one :git_extra, :foreign_key =>'repository_id', :class_name => 'GitRepositoryExtra', :dependent => :destroy

					# initialize association from git repository -> cia_notifications
					has_many :cia_notifications, :foreign_key =>'repository_id', :class_name => 'GitCiaNotification', :dependent => :destroy, :extend => GitHosting::Patches::RepositoryCiaFilters::FilterMethods

					include(InstanceMethods)
				end
			end
		end
	end
end

# Patch in changes
Repository.send(:include, GitHosting::Patches::RepositoryPatch)
