module GitolitablePaths
  extend ActiveSupport::Concern

  # This is the (possibly non-unique) basename for the git repository
  def redmine_name
    identifier.blank? ? project.identifier : identifier
  end


  def gitolite_repository_path
    "#{RedmineGitolite::Config.get_setting(:gitolite_global_storage_dir)}#{gitolite_repository_name}.git"
  end


  def gitolite_repository_name
    File.expand_path(File.join("./", RedmineGitolite::Config.get_setting(:gitolite_redmine_storage_dir), get_full_parent_path, git_cache_id), "/")[1..-1]
  end


  def redmine_repository_path
    File.expand_path(File.join("./", get_full_parent_path, git_cache_id), "/")[1..-1]
  end


  def new_repository_name
    gitolite_repository_name
  end


  def old_repository_name
    "#{self.url.gsub(RedmineGitolite::Config.get_setting(:gitolite_global_storage_dir), '').gsub('.git', '')}"
  end


  def exists_in_gitolite?
    RedmineGitolite::GitoliteWrapper.sudo_dir_exists?(gitolite_repository_path)
  end


  def empty?
    if extra_info.nil? || ( !extra_info.has_key?('heads') && !extra_info.has_key?('branches') )
      true
    else
      false
    end
  end


  def get_full_parent_path
    return '' if !RedmineGitolite::Config.get_setting(:hierarchical_organisation, true)
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
