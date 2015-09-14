module Gitolitable
  module Cache
    extend ActiveSupport::Concern

    included do
      class << self

        # Are repositories identifier unique?
        #
        def repo_ident_unique?
          RedmineGitHosting::Config.unique_repo_identifier?
        end


        # Translate repository path into a unique ID for use in caching of git commands.
        #
        def repo_path_to_git_cache_id(repo_path)
          repo = find_by_path(repo_path, loose: true)
          repo ? repo.git_cache_id : nil
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
        #
        def find_by_path(path, flags = {})
          parseit = path.match(/\A.*?(([^\/]+)\/)?([^\/]+?)(\.git)?\z/)
          return nil if parseit.nil?

          project = Project.find_by_identifier(parseit[3])

          # return default or first repo with blank identifier (or first Git repo--very rare?)
          if project
            project.repository || project.repo_blank_ident || project.gitolite_repos.first

          elsif repo_ident_unique? || flags[:loose] && parseit[2].nil?
            find_by_identifier(parseit[3])

          elsif parseit[2]
            project = Project.find_by_identifier(parseit[2])

            if project.nil?
              find_by_identifier(parseit[3])
            else
              find_by_identifier_and_project_id(parseit[3], project.id) || (flags[:loose] && find_by_identifier(parseit[3]))
            end
          end
        end

      end
    end


    # If repositories identifiers are unique, identifier forms a unique label,
    # else use directory notation: <project identifier>/<repo identifier>
    #
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


    # Note: RedmineGitHosting::Cache doesn't know about repository object, it only knows *git_cache_id*.
    #
    def empty_cache!
      RedmineGitHosting::Cache.clear_cache_for_repository(git_cache_id)
    end

  end
end
