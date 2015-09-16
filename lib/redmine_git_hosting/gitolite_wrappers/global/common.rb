module RedmineGitHosting
  module GitoliteWrappers
    module Global
      module Common

        def redmine_gitolite_key
          'redmine_gitolite_admin_id_rsa'
        end


        def all_repository
          '@all'
        end


        def all_repository_config
          gitolite_config.repos[all_repository]
        end


        def rw_access_config
          repo_conf = ::Gitolite::Config::Repo.new(all_repository)
          repo_conf.permissions = rw_access_perms
          repo_conf
        end


        def rw_access_perms
          permissions = {}
          permissions['RW+'] = {}
          permissions['RW+'][''] = [redmine_gitolite_key]
          [permissions]
        end


        def repo_conf
          all_repository_config
        end


        def perms
          repo_conf.permissions.select { |p| p.has_key? 'RW+' }
        end


        # RedmineGitHosting key can act on any refspec ('') so it should be in that 'subgroup'
        #
        def users
          perms[0]['RW+']['']
        end

      end
    end
  end
end
