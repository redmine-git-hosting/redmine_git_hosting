require_dependency 'my_controller'
module GitHosting
	module Patches
		module MyControllerPatch
			
			def account_with_public_keys
				account_without_public_keys
			end
			
		
			def self.included(base)
				base.class_eval do
					unloadable
				end
				base.send(:alias_method_chain, :account, :public_keys)
			end
		end
	end
end
MyController.send(:include, GitHosting::Patches::RepositoriesControllerPatch) unless RepositoriesController.include?(GitHosting::Patches::RepositoriesControllerPatch)
