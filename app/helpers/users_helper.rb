require_dependency 'users_helper'

# Add a tab for editing public keys to the user's page....
module GitHostingUsersHelperPatch
    def self.included(base)
	base.send(:include, InstanceMethods)
	base.class_eval do
	    alias_method_chain :user_settings_tabs, :public_keys
	end
    end

    module InstanceMethods
	# Add a public_keys tab to the user administration page
	def user_settings_tabs_with_public_keys
	    tabs = user_settings_tabs_without_public_keys
	    tabs << { :name => 'keys', :partial => 'gitolite_public_keys/view', :label => :label_public_keys }
	    return tabs
	end
    end
end


UsersHelper.send(:include, GitHostingUsersHelperPatch)
