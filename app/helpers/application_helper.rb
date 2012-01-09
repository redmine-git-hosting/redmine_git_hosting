module ApplicationHelper

	# 
	# These functions are for backward compatability with versions of redmine < 1.3
	# Only define these if not already defined (although load-order seems to load plugin
	# helpers before main ones, so check not necessary).
	#
	# 1/05/12
	# John Kubiatowicz
	if !defined?(labelled_form_for)
    		def labelled_form_for(*args, &proc)
                	args << {} unless args.last.is_a?(Hash)
 			options = args.last
			options.merge!({:builder => TabularFormBuilder,:lang => current_language})
			form_for(*args, &proc)
                end
    	end

	if !defined?(labelled_remote_form_for)
		def labelled_remote_form_for(*args, &proc)
			args << {} unless args.last.is_a?(Hash)
 			options = args.last
			options.merge!({:builder => TabularFormBuilder,:lang => current_language})
			remote_form_for(*args, &proc)
                end
        end

end
