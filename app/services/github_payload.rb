class GithubPayload
  unloadable

  attr_reader :repository
  attr_reader :project
  attr_reader :refs


  def initialize(repository, refs)
    @repository = repository
    @project    = repository.project
    @refs       = refs
    @payloads   = []
  end


  def build
    build_payloads
  end


  private


    def logger
      RedmineGitHosting.logger
    end


    # Returns an array of GitHub post-receive hook style hashes
    # http://help.github.com/post-receive-hooks/
    def build_payloads
      refs.each do |ref|
        # Get revisions range
        range = get_revisions_from_ref(ref)
        next if range.nil?
        @payloads << build_payload(ref, range)
      end
      @payloads
    end


    def get_revisions_from_ref(ref)
      oldhead, newhead, refname = ref.split(',')

      # Only pay attention to branch updates
      return nil if !refname.match(/refs\/heads\//)

      # Get branch name
      branch_name = refname.gsub('refs/heads/', '')

      if newhead.match(/^0{40}$/)
        # Deleting a branch
        logger.info("Deleting branch '#{branch_name}'")
        range = nil
      elsif oldhead.match(/^0{40}$/)
        # Creating a branch
        logger.info("Creating branch '#{branch_name}'")
        range = newhead
      else
        range = "#{oldhead}..#{newhead}"
      end

      range
    end


    def build_payload(ref, range)
      revisions_in_range = get_revisions_in_range(range)
      logger.debug("Revisions in range : #{revisions_in_range.split().join(' ')}")

      # Get refs
      oldhead, newhead, refname = ref.split(',')

      # Build payload hash
      payload = {
        :before     => oldhead,
        :after      => newhead,
        :ref        => refname,
        :commits    => build_commits_list(revisions_in_range),
        :pusher     => {
          :name  => Setting["app_title"],
          :email => Setting["mail_from"]
        },
        :repository => {
          :description => project.description,
          :fork        => false,
          :forks       => 0,
          :homepage    => project.homepage,
          :name        => repository.redmine_name,
          :open_issues => project.issues.open.length,
          :watchers    => 0,
          :private     => !project.is_public,
          :url         => repository_url,
          :owner       => {
            :name  => Setting["app_title"],
            :email => Setting["mail_from"]
          }
        }
      }

      payload
    end


    def build_commits_list(revisions_in_range)
      commits_list = []
      revisions_in_range.split().each do |rev|
        revision = repository.find_changeset_by_name(rev.strip)
        next if revision.nil?
        commits_list << build_commit_entry(revision)
      end
      commits_list
    end


    def build_commit_entry(revision)
      {
        :id        => revision.revision,
        :message   => revision.comments,
        :timestamp => revision.committed_on,
        :added     => revision.filechanges.select{|c| c.action == "A" }.map(&:path),
        :modified  => revision.filechanges.select{|c| c.action == "M" }.map(&:path),
        :removed   => revision.filechanges.select{|c| c.action == "D" }.map(&:path),
        :url       => url_for_revision(revision.revision),
        :author    => {
          :name  => revision.committer.gsub(/^([^<]+)\s+.*$/, '\1'),
          :email => revision.committer.gsub(/^.*<([^>]+)>.*$/, '\1')
        }
      }
    end


    def url_for_revision(revision)
      Rails.application.routes.url_helpers.url_for(
        controller: 'repositories', action: 'revision',
        id: project, repository_id: repository.identifier_param, rev: revision,
        only_path: false, host: Setting['host_name'], protocol: Setting['protocol']
      )
    end


    def repository_url
      Rails.application.routes.url_helpers.url_for(
        controller: 'repositories', action: 'show',
        id: project, repository_id: repository.identifier_param,
        only_path: false, host: Setting['host_name'], protocol: Setting['protocol']
      )
    end


    def get_revisions_in_range(range)
      RedmineGitHosting::Commands.sudo_capture('git', "--git-dir=#{repository.gitolite_repository_path}", 'rev-list', '--reverse', range)
    end

end
