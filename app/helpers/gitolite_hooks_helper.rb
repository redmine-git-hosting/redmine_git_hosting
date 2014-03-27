require 'net/http'
require 'net/https'
require 'uri'

module GitoliteHooksHelper

  def logger
    RedmineGitolite::Log.get_logger(:git_hooks)
  end


  def validate_encoded_time(clear_time, encoded_time, key)
    valid = false

    begin
      cur_time_seconds  = Time.new.utc.to_i
      test_time_seconds = clear_time.to_i

      if cur_time_seconds - test_time_seconds < 5*60
        test_encoded = Digest::SHA1.hexdigest(clear_time.to_s + key.to_s)
        if test_encoded.to_s == encoded_time.to_s
          valid = true
        end
      end
    rescue Exception => e
      logger.error { "Error in validate_encoded_time(): #{e.message}" }
    end

    return valid
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
      revisions_in_range = RedmineGitolite::GitHosting.execute_command(:git_cmd, "--git-dir='#{@repository.gitolite_repository_path}' rev-list --reverse #{range}")
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

        revision.changes.each do |change|
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
        :repository => {
          :description => @project.description,
          :fork        => false,
          :forks       => 0,
          :homepage    => @project.homepage,
          :name        => @project.identifier,
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


  def post_data(url, payload, opts={})
    uri  = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    if opts[:method] == :post
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data({"payload" => payload.to_json})
    else
      request = Net::HTTP::Get.new(uri.request_uri)
    end

    message = ""

    begin
      res = http.start {|openhttp| openhttp.request request}
      if !res.is_a?(Net::HTTPSuccess)
        message = "Return code : #{res.code} (#{res.message})."
        failed = true
      else
        message = res.body
        failed = false
      end
    rescue => e
      message = "Exception : #{e.message}"
      failed = true
    end

    return failed, message
  end

end
