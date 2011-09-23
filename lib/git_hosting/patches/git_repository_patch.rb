module GitHosting
	module Patches
		module GitRepositoryPatch

			def report_last_commit_with_always_true
				true
			end
			def extra_report_last_commit_with_always_true
				true
			end


			def self.included(base)
				base.class_eval do
					unloadable
				end
				begin
					base.send(:alias_method_chain, :report_last_commit, :always_true)
					base.send(:alias_method_chain, :extra_report_last_commit, :always_true)
				rescue
				end

			end
		end
	end
end
