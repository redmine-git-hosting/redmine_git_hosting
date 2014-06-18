include Rails.application.routes.url_helpers

class GithubPayload
  unloadable


  attr_reader :payload


  def initialize(repository, payload)
    @repository = repository
    @project    = repository.project
    @payload    = build_payload(payload)
  end


  private


  def logger
    RedmineGitolite::Log.get_logger(:git_hooks)
  end


  # Returns an array of GitHub post-receive hook style hashes
  # http://help.github.com/post-receive-hooks/
  def build_payload(refs)
    payload = []

    refs.each do |ref|

      oldhead, newhead, refname = ref.split(',')

      # Only pay attention to branch updates
      next if !refname.match(/refs\/heads\//)

      branch = refname.gsub('refs/heads/', '')

      if newhead.match(/^0{40}$/)
        # Deleting a branch
        logger.info { "Deleting branch '#{branch}'" }
        next
      elsif oldhead.match(/^0{40}$/)
        # Creating a branch
        logger.info { "Creating branch '#{branch}'" }
        range = newhead
      else
        range = "#{oldhead}..#{newhead}"
      end

      # Grab the repository path
      revisions_in_range = RedmineGitolite::GitoliteWrapper.sudo_capture('git', "--git-dir=#{@repository.gitolite_repository_path}", 'rev-list', '--reverse', range)
      logger.debug { "Revisions in range : #{revisions_in_range.split().join(' ')}" }

      commits = []

      revisions_in_range.split().each do |rev|
        logger.debug { "Revision : '#{rev.strip}'" }
        revision = @repository.find_changeset_by_name(rev.strip)
        next if revision.nil?

        revision_url = url_for(:controller => 'repositories', :action => 'revision',
                               :id => @project, :repository_id => @repository.identifier_param, :rev => rev,
                               :only_path => false, :host => Setting['host_name'], :protocol => Setting['protocol'])

        commit = {
          :id        => revision.revision,
          :message   => revision.comments,
          :timestamp => revision.committed_on,
          :added     => [],
          :modified  => [],
          :removed   => [],
          :url       => revision_url,
          :author    => {
            :name  => revision.committer.gsub(/^([^<]+)\s+.*$/, '\1'),
            :email => revision.committer.gsub(/^.*<([^>]+)>.*$/, '\1')
          }
        }

        revision.filechanges.each do |change|
          if change.action == "M"
            commit[:modified] << change.path
          elsif change.action == "A"
            commit[:added] << change.path
          elsif change.action == "D"
            commit[:removed] << change.path
          end
        end

        commits << commit
      end

      repository_url = url_for(:controller => 'repositories', :action => 'show',
                               :id => @project, :repository_id => @repository.identifier_param,
                               :only_path => false, :host => Setting["host_name"], :protocol => Setting["protocol"])

      payload << {
        :before     => oldhead,
        :after      => newhead,
        :ref        => refname,
        :commits    => commits,
        :pusher     => {
          :name  => Setting["app_title"],
          :email => Setting["mail_from"]
        },
        :repository => {
          :description => @project.description,
          :fork        => false,
          :forks       => 0,
          :homepage    => @project.homepage,
          :name        => @repository.redmine_name,
          :open_issues => @project.issues.open.length,
          :watchers    => 0,
          :private     => !@project.is_public,
          :url         => repository_url,
          :owner       => {
            :name  => Setting["app_title"],
            :email => Setting["mail_from"]
          }
        }
      }
    end

    return payload
  end

end
