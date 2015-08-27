module PluginSettingsValidation
  module StorageConfig
    extend ActiveSupport::Concern

    PATHS_TO_VALIDATE = [:gitolite_global_storage_dir, :gitolite_redmine_storage_dir, :gitolite_recycle_bin_dir, :gitolite_local_code_dir]

    included do
      # Gitolite Storage Config
      add_accessor :gitolite_global_storage_dir,
                   :gitolite_redmine_storage_dir,
                   :gitolite_recycle_bin_dir,
                   :gitolite_local_code_dir,
                   :gitolite_lib_dir

      before_validation do
        self.gitolite_global_storage_dir  = strip_value(gitolite_global_storage_dir)
        self.gitolite_redmine_storage_dir = strip_value(gitolite_redmine_storage_dir)
        self.gitolite_recycle_bin_dir     = strip_value(gitolite_recycle_bin_dir)
        self.gitolite_local_code_dir      = strip_value(gitolite_local_code_dir)
        self.gitolite_lib_dir             = strip_value(gitolite_lib_dir)
      end

      validates_presence_of :gitolite_global_storage_dir, :gitolite_recycle_bin_dir, :gitolite_lib_dir
      validates_presence_of :gitolite_local_code_dir, if: Proc.new { RedmineGitHosting::Config.gitolite_version == 3 }

      validates_each PATHS_TO_VALIDATE do |record, attr, value|
        # *gitolite_local_code_dir* is only available with Gitolite 3
        next if attr == :gitolite_local_code_dir && RedmineGitHosting::Config.gitolite_version != 3
        record.errors.add(attr, 'must be relative') if value.starts_with?('/')
      end
    end

  end
end
