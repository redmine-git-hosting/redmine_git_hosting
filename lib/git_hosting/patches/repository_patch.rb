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
							e = GitRepositoryExtra.new()
							new_repo.extra = e
						end
					end
					return new_repo
				end
			end


			def self.included(base)
				base.extend(ClassMethods)
				base.class_eval do
					unloadable
					class << self
						alias_method_chain :factory, :git_extra_init
					end
				end

			end
		end
	end
end
