module PluginSettingsValidation
  module StorageConfig
    extend ActiveSupport::Concern

    PATHS_TO_VALIDATE = %i[gitolite_global_storage_dir gitolite_redmine_storage_dir gitolite_recycle_bin_dir].freeze

    included do
      # Gitolite Storage Config
      add_accessor :gitolite_global_storage_dir,
                   :gitolite_redmine_storage_dir,
                   :gitolite_recycle_bin_dir

      before_validation do
        self.gitolite_global_storage_dir  = strip_value(gitolite_global_storage_dir)
        self.gitolite_redmine_storage_dir = strip_value(gitolite_redmine_storage_dir)
        self.gitolite_recycle_bin_dir     = strip_value(gitolite_recycle_bin_dir)
      end

      validates_presence_of :gitolite_global_storage_dir, :gitolite_recycle_bin_dir

      validates_each PATHS_TO_VALIDATE do |record, attr, value|
        record.errors.add(attr, 'must be relative') if value.starts_with?('/')
      end
    end
  end
end
