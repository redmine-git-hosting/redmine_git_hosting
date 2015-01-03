module GitolitablePaths
  extend ActiveSupport::Concern

  # This is the (possibly non-unique) basename for the git repository
  def redmine_name
    identifier.blank? ? project.identifier : identifier
  end


  def gitolite_repository_path
    "#{RedmineGitHosting::Config.gitolite_global_storage_dir}#{gitolite_repository_name_with_extension}"
  end


  def gitolite_repository_name
    File.expand_path(File.join("./", RedmineGitHosting::Config.gitolite_redmine_storage_dir, get_full_parent_path, git_cache_id), "/")[1..-1]
  end


  def gitolite_repository_name_with_extension
    "#{gitolite_repository_name}.git"
  end


  def redmine_repository_path
    File.expand_path(File.join("./", get_full_parent_path, git_cache_id), "/")[1..-1]
  end


  def new_repository_name
    gitolite_repository_name
  end


  def old_repository_name
    "#{self.url.gsub(RedmineGitHosting::Config.gitolite_global_storage_dir, '').gsub('.git', '')}"
  end


  private


    def get_full_parent_path
      return '' if !RedmineGitHosting::Config.hierarchical_organisation?
      parent_parts = []
      p = project
      while p.parent
        parent_id = p.parent.identifier.to_s
        parent_parts.unshift(parent_id)
        p = p.parent
      end
      parent_parts.join("/")
    end

end
