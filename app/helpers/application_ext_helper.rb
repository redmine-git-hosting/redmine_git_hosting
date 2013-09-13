module ApplicationExtHelper

  # These functions are for backward compatability with versions of redmine < 1.3
  # Only define these if not already defined (although load-order seems to load plugin
  # helpers before main ones, so check not necessary).
  #
  # 1/05/12 John Kubiatowicz
  # 4/01/12 Only define backward-compatible functions if TabularFormBuilder exists
  #   (seems some versions of rails will go ahead and define these functions
  #   and override properly defined versions).  Note that Redmine 1.4+ removes
  #   lib/tabular_form_builder.rb but defines these functions using new
  #   builder functions...
  # 8/10/12 Added "labelled_fields_for", since that seems to be coming in 1.4
  if !defined?(labelled_form_for) && File.exists?(Rails.root.join("lib/tabular_form_builder.rb"))
    def labelled_form_for(*args, &proc)
      args << {} unless args.last.is_a?(Hash)
      options = args.last
      options.merge!({:builder => Redmine::Views::LabelledFormBuilder, :lang => current_language})
      form_for(*args, &proc)
    end
  end

  if !defined?(labelled_remote_form_for) && File.exists?(Rails.root.join("lib/tabular_form_builder.rb"))
    def labelled_remote_form_for(*args, &proc)
      args << {} unless args.last.is_a?(Hash)
      options = args.last
      options.merge!({:builder => Redmine::Views::LabelledFormBuilder, :lang => current_language, :remote => true})
      form_for(*args, &proc)
    end
  end

  if !defined?(labelled_fields_for) && File.exists?(Rails.root.join("lib/tabular_form_builder.rb"))
    def labelled_fields_for(*args, &proc)
      args << {} unless args.last.is_a?(Hash)
      options = args.last
      options.merge!({:builder => Redmine::Views::LabelledFormBuilder, :lang => current_language})
      fields_for(*args, &proc)
    end
  end

end
