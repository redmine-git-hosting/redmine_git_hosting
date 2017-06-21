module Gitolitable
  module Paths
    extend ActiveSupport::Concern


    # This is the repository path from Redmine point of view.
    # It is used to build HTTP(s) urls (including GoLang url).
    # It doesn't contain references to internal directories like *gitolite_global_storage_dir* or *gitolite_redmine_storage_dir*
    # to stay abstract from the real repository location.
    # In this case, the real repository path is deduced from the path given thanks to the *find_by_path* method.
    #
    # Example : blabla/test-blabla/uuuuuuuuuuu/oooooo
    #
    # Call File.expand_path to add then remove heading /
    #
    def redmine_repository_path
      File.expand_path(File.join('./', get_full_parent_path, git_cache_id), '/')[1..-1]
    end


    # This is the Gitolite repository identifier as it should appear in Gitolite config file.
    # Example : redmine/blabla/test-blabla/uuuuuuuuuuu/oooooo
    # (with 'redmine' a subdir of the Gitolite storage directory)
    #
    # Call File.expand_path to add then remove heading /
    #
    def gitolite_repository_name
      repo_depth = RedmineGitHosting::Config.get_setting(:gitolite_one_level_repo_depth, true)
      redmine_storage = RedmineGitHosting::Config.get_setting(:gitolite_redmine_storage_dir, false)
      repo_path = File.expand_path(File.join('./', redmine_storage, get_full_parent_path, git_cache_id), '/')[1..-1]

      if repo_depth
        if get_full_parent_path.blank?
          # we are in parent project
          new_repo = redmine_storage.blank? ? repo_path : repo_path.gsub(redmine_storage, "")[0..-1]
          if new_repo.split("/").size == 2
            redmine_storage.blank? ? new_repo : redmine_storage + new_repo
          else
            redmine_storage.blank? ? new_repo + "/" + new_repo : redmine_storage + new_repo + "/" + new_repo
          end

        else
          # if parent path isnt blank, we are in subproject
          new_repo = redmine_storage.blank? ? repo_path.gsub(get_full_parent_path, "")[1..-1] :
            repo_path.gsub(redmine_storage + get_full_parent_path, "")[1..-1]
          if new_repo.split("/").size == 2
            redmine_storage.blank? ? new_repo : redmine_storage + new_repo
          else
            redmine_storage.blank? ? new_repo + "/" + new_repo : redmine_storage + new_repo + "/" + new_repo
          end

        end
      else
        # default Hierachical style
        repo_path
      end

    end


    # The Gitolite repository identifier with the .git extension.
    # Example : redmine/blabla/test-blabla/uuuuuuuuuuu/oooooo.git
    #
    def gitolite_repository_name_with_extension
      "#{gitolite_repository_name}.git"
    end


    # This is the relative path to the Gitolite repository.
    # Example : repositories/redmine/blabla/test-blabla/uuuuuuuuuuu/oooooo.git
    # (with 'repositories' the Gitolite storage directory).
    #
    def gitolite_repository_path
      File.join(RedmineGitHosting::Config.gitolite_global_storage_dir, gitolite_repository_name_with_extension)
    end


    # This is the full absolute path to the Gitolite repository.
    # Example : /home/git/repositories/redmine/blabla/test-blabla/uuuuuuuuuuu/oooooo.git
    #
    def gitolite_full_repository_path
      File.join(RedmineGitHosting::Config.gitolite_home_dir, gitolite_repository_path)
    end


    # A syntaxic sugar used to move repository from a location to an other
    # Example : repositories/blabla/test-blabla/uuuuuuuuuuu/oooooo
    #
    def new_repository_name
      gitolite_repository_name
    end


    # Used to move repository from a location to an other.
    # At this point repository url still points to the old location but
    # it contains the Gitolite storage directory in its path and the '.git' extension.
    # Strip them to get the old repository name.
    # Example :
    #   before : repositories/redmine/blabla/test-blabla/uuuuuuuuuuu/oooooo.git
    #   after  : redmine/blabla/test-blabla/uuuuuuuuuuu/oooooo
    #
    def old_repository_name
      url.gsub(RedmineGitHosting::Config.gitolite_global_storage_dir, '').gsub('.git', '')
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
        parent_parts.join('/')
      end

  end
end
