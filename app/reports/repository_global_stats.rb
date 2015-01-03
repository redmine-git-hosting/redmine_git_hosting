class RepositoryGlobalStats

  include Redmine::I18n

  attr_reader :repository


  def initialize(repository)
    @repository = repository
  end


  def build
    build_report
  end


  private


    def build_report
      {
        l(:label_total_commits)               => total_commits,
        l(:label_total_contributors)          => committers,
        l(:label_first_commit_date)           => first_commit.commit_date,
        l(:label_latest_commit_date)          => last_commit.commit_date,
        l(:label_active_for)                  => "#{active_for} #{l(:label_active_days)}",
        l(:label_average_commit_per_day)      => average_commit_per_day,
        l(:label_average_contributor_commits) => average_contributor_commits
      }
    end


    def total_commits
      @total_commits ||= Changeset.where('repository_id = ?', repository.id).count
    end


    def first_commit
      @first_commit ||= Changeset.where('repository_id = ?', repository.id).order('commit_date ASC').first
    end


    def last_commit
      @last_commit ||= Changeset.where('repository_id = ?', repository.id).order('commit_date ASC').last
    end


    def active_for
      @active_for ||= (last_commit.commit_date - first_commit.commit_date).to_i
    end


    def average_commit_per_day
      @average_commit_per_day ||= total_commits.fdiv(active_for).round(2)
    end


    def average_contributor_commits
      @average_contributor_commits ||= total_commits.fdiv(committers).round(2)
    end


    def committers
      @committers ||= redmine_committers + external_committers
    end


    def redmine_committers
      @redmine_committers ||= Changeset.where('repository_id = ?', repository.id).where('user_id IS NOT NULL').select(:user_id).uniq.count
    end


    def external_committers
      @external_committers ||= Changeset.where('repository_id = ?', repository.id).where(user_id: nil).select(:committer).uniq.count
    end

end
