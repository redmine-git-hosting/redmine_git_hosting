module ApplicationHelper

	# 
	# These functions are for backward compatability with versions of redmine < 1.3
	# Only define these if not already defined (although load-order seems to load plugin
	# helpers before main ones, so check not necessary).
	#
	# 1/05/12 John Kubiatowicz
  	# 4/01/12 Only define backward-compatible functions if TabularFormBuilder exists
  	#	  (seems some versions of rails will go ahead and define these functions
	# 	  and override properly defined versions).  Note that Redmine 1.4+ removes
  	# 	  lib/tabular_form_builder.rb but defines these functions using new
	#	  builder functions...
	if !defined?(labelled_form_for) && File.exists?(Rails.root.join("lib/tabular_form_builder.rb"))
    		def labelled_form_for(*args, &proc)
                	args << {} unless args.last.is_a?(Hash)
 			options = args.last
			options.merge!({:builder => TabularFormBuilder,:lang => current_language})
			form_for(*args, &proc)
                end
    	end

	if !defined?(labelled_remote_form_for) && File.exists?(Rails.root.join("lib/tabular_form_builder.rb"))
		def labelled_remote_form_for(*args, &proc)
			args << {} unless args.last.is_a?(Hash)
 			options = args.last
			options.merge!({:builder => TabularFormBuilder,:lang => current_language})
			remote_form_for(*args, &proc)
                end
        end

	# Generic helper functions
        def reldir_add_dotslash(path)
        	# Is this a relative path?
        	stripped = (path || "").lstrip.rstrip
		norm = File.expand_path(stripped,"/")
          	((stripped[0,1] != "/")?".":"") + norm + ((norm[-1,1] != "/")?"/":"")
        end
        	
        # Port-receive Mode
        def post_receive_mode(prurl)
 		if prurl.active==0
                	l(:label_inactive)
                elsif prurl.mode == :github
                	l(:label_github_post)
                else
                	l(:label_empty_get)
                end
        end

        # Refspec for mirrors
	def refspec(mirror, max_refspec=0)
        	if mirror.push_mode==RepositoryMirror::PUSHMODE_MIRROR
                	l(:all_references)
                else
                	result=[]
                	result << l(:all_branches) if mirror.include_all_branches
                	result << l(:all_tags) if mirror.include_all_tags
                	result << mirror.explicit_refspec if (max_refspec == 0) || ((1..max_refspec) === mirror.explicit_refspec.length)
                	result << l(:explicit) if (max_refspec > 0) && (mirror.explicit_refspec.length > max_refspec)
                	result.join(",<br />")
                end
        end        

        # Mirror Mode
        def mirror_mode(mirror)
        	if mirror.active==0
                	l(:label_inactive)
                else
                	[l(:label_mirror),l(:label_forced),l(:label_unforced)][mirror.push_mode] 
                end
        end
end
