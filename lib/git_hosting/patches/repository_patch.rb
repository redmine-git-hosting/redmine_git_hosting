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
			end


			def self.included(base)
				base.class_eval do
					unloadable
				end
				base.extend(ClassMethods)
			end
		end
	end
end
Repository.send(:include, GitHosting::Patches::RepositoryPatch) unless Repository.include?(GitHosting::Patches::RepositoryPatch)
