module GitolitableCache
  extend ActiveSupport::Concern

  included do
    before_destroy :clean_cache, prepend: true

    class << self

      # Repo ident unique
      def repo_ident_unique?
        RedmineGitolite::Config.get_setting(:unique_repo_identifier, true)
      end


      def have_duplicated_identifier?
        if ((self.all.map(&:identifier).inject(Hash.new(0)) do |h, x|
            h[x] += 1 unless x.blank?
            h
          end.values.max) || 0) > 1
          # Oops -- have duplication
          return true
        else
          return false
        end
      end


      # Translate repository path into a unique ID for use in caching of git commands.
      #
      # We perform caching here to speed this up, since this function gets called
      # many times during the course of a repository lookup.
      @@cached_path = nil
      @@cached_id = nil
      def repo_path_to_git_cache_id(repo_path)
        # Return cached value if pesent
        return @@cached_id if @@cached_path == repo_path

        repo = repo_path_to_object(repo_path)

        if repo
          # Cache translated id path, return id
          @@cached_path = repo_path
          @@cached_id = repo.git_cache_id
        else
          # Hm... clear cache, return nil
          @@cached_path = nil
          @@cached_id = nil
        end
      end


      def repo_path_to_object(repo_path)
        find_by_path(repo_path, loose: true)
      end


      # Parse a path of the form <proj1>/<proj2>/<proj3>/<repo> and return the specified
      # repository.  If either 'repo_ident_unique?' is true or the <repo> is a project
      # identifier, just return the last component.  Otherwise,
      # use the immediate parent (<proj3>) to try to identify the repo.
      #
      # Flags:
      #  :loose => true : Try to identify corresponding repo even if path is not quite correct
      #
      # Note that the :loose flag is used when interpreting the contents of the
      # repository.  If switching back and forth between the "repo_ident_unique?"
      # form, it will still identify the repository (as long as there are not more than
      # one repo with the same identifier.
      #
      # Example of data captured by regex :
      # <MatchData "test/test2/test3/test4/test5.git" 1:"test4/" 2:"test4" 3:"test5" 4:".git">
      # <MatchData "blabla2.git" 1:nil 2:nil 3:"blabla2" 4:".git">

      def find_by_path(path, flags = {})
        if parseit = path.match(/^.*?(([^\/]+)\/)?([^\/]+?)(\.git)?$/)
          if proj = Project.find_by_identifier(parseit[3])
            # return default or first repo with blank identifier (or first Git repo--very rare?)
            proj && (proj.repository || proj.repo_blank_ident || proj.gitolite_repos.first)
          elsif repo_ident_unique? || flags[:loose] && parseit[2].nil?
            find_by_identifier(parseit[3])
          elsif parseit[2] && proj = Project.find_by_identifier(parseit[2])
            find_by_identifier_and_project_id(parseit[3], proj.id) ||
            flags[:loose] && find_by_identifier(parseit[3]) || nil
          else
            find_by_identifier(parseit[3]) || nil
          end
        else
          nil
        end
      end

    end
  end


  # If repo identifiers unique, identifier forms unique label
  # Else, use directory notation: <project identifier>/<repo identifier>
  def git_cache_id
    if identifier.blank?
      # Should only happen with one repo/project (the default)
      project.identifier
    elsif self.class.repo_ident_unique?
      identifier
    else
      "#{project.identifier}/#{identifier}"
    end
  end


  private


    def clean_cache
      RedmineGitolite::Log.get_logger(:global).info { "Clean cache before delete repository '#{gitolite_repository_name}'" }
      RedmineGitolite::Cache.clear_cache_for_repository(self)
    end

end
