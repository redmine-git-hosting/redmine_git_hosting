require 'json'

module RedmineHooks
  class GithubIssuesSync < Base

    include HttpHelper


    def call
      sync_with_github
    end


    def project
      object
    end


    def params
      payloads
    end


    private


      def github_issue
        GithubIssue.find_by_github_id(params[:issue][:id])
      end


      def redmine_issue
        Issue.find_by_subject(params[:issue][:title])
      end


      def sync_with_github
        create_relation = false

        ## We don't have stored relation
        if github_issue.nil?

          ## And we don't have issue in Redmine
          if redmine_issue.nil?
            create_relation = true
            redmine_issue = create_redmine_issue
          else
            ## Create relation and update issue
            create_relation = true
            redmine_issue = update_redmine_issue(redmine_issue)
          end
        else
          ## We have one relation, update issue
          redmine_issue = update_redmine_issue(github_issue.issue)
        end

        if create_relation
          github_issue = GithubIssue.new
          github_issue.github_id = params[:issue][:id]
          github_issue.issue_id = redmine_issue.id
          github_issue.save!
        end

        if params.has_key?(:comment)
          issue_journal = GithubComment.find_by_github_id(params[:comment][:id])

          if issue_journal.nil?
            issue_journal = create_issue_journal(github_issue.issue)

            github_comment = GithubComment.new
            github_comment.github_id = params[:comment][:id]
            github_comment.journal_id = issue_journal.id
            github_comment.save!
          end
        end
      end


      def create_redmine_issue
        logger.info('Github Issues Sync : create new issue')

        issue             = project.issues.new
        issue.tracker_id  = project.trackers.first.try(:id)
        issue.subject     = params[:issue][:title].chomp[0, 255]
        issue.description = params[:issue][:body]
        issue.updated_on  = params[:issue][:updated_at]
        issue.created_on  = params[:issue][:created_at]

        ## Get user mail
        user = find_user(params[:issue][:user][:url])
        issue.author = user

        issue.save!
        return issue
      end


      def create_issue_journal(issue)
        logger.info("Github Issues Sync : create new journal for issue '##{issue.id}'")

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


      def update_redmine_issue(issue)
        logger.info("Github Issues Sync : update issue '##{issue.id}'")

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
        post_failed, user_data = http_get(url)
        user_data = JSON.parse(user_data)

        user = User.find_by_mail(user_data['email'])

        if user.nil?
          logger.info("Github Issues Sync : cannot find user '#{user_data['email']}' in Redmine, use anonymous")
          user = User.anonymous
          user.mail = user_data['email']
          user.firstname = user_data['name']
          user.lastname  = user_data['login']
        end

        return user
      end

  end
end
