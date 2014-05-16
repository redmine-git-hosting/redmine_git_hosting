require 'digest/sha1'
require 'json'
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


  def create_issue_journal(issue, params)
    logger.info { "Github Issues Sync : create new journal for issue '##{issue.id}'" }

    journal = Journal.new
    journal.journalized_id = issue.id
    journal.journalized_type = 'Issue'
    journal.notes = params[:comment][:body]
    journal.created_on = params[:comment][:created_at]

    ## Get user mail
    user = find_user(params[:comment][:user][:url])
    journal.user_id = user.id

    journal.save!
    return journal
  end


  def create_redmine_issue(params)
    logger.info { "Github Issues Sync : create new issue" }

    issue = Issue.new
    issue.project_id = @project.id
    issue.tracker_id = @project.trackers.find(:first).try(:id)
    issue.subject = params[:issue][:title].chomp[0, 255]
    issue.description = params[:issue][:body]
    issue.updated_on = params[:issue][:updated_at]
    issue.created_on = params[:issue][:created_at]

    ## Get user mail
    user = find_user(params[:issue][:user][:url])
    issue.author = user

    issue.save!
    return issue
  end


  def update_redmine_issue(issue, params)
    logger.info { "Github Issues Sync : update issue '##{issue.id}'" }

    if params[:issue][:state] == 'closed'
      issue.status_id = 5
    else
      issue.status_id = 1
    end

    issue.subject = params[:issue][:title].chomp[0, 255]
    issue.description = params[:issue][:body]
    issue.updated_on = params[:issue][:updated_at]

    issue.save!
    return issue
  end


  def find_user(url)
    post_failed, user_data = post_data(url, "", :method => :get)
    user_data = JSON.parse(user_data)

    user = User.find_by_mail(user_data['email'])

    if user.nil?
      logger.info { "Github Issues Sync : cannot find user '#{user_data['email']}' in Redmine, use anonymous" }
      user = User.anonymous
      user.mail = user_data['email']
      user.firstname = user_data['name']
      user.lastname  = user_data['login']
    end

    return user
  end


  # Parse a reference component.  Three possibilities:
  #
  # 1) refs/type/name
  # 2) name
  #
  # here, name can have many components.
  @@refcomp = "[\\.\\-\\w_\\*]+"
  def refcomp_parse(spec)
    if (refcomp_parse = spec.match(/^(refs\/)?((#{@@refcomp})\/)?(#{@@refcomp}(\/#{@@refcomp})*)$/))
      if refcomp_parse[1]
        # Should be first class.  If no type component, return fail
        if refcomp_parse[3]
          {:type => refcomp_parse[3], :name => refcomp_parse[4]}
        else
          nil
        end
      elsif refcomp_parse[3]
        {:type => nil, :name => (refcomp_parse[3] + "/" + refcomp_parse[4])}
      else
        {:type => nil, :name => refcomp_parse[4]}
      end
    else
      nil
    end
  end

end
