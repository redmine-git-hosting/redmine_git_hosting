class RepositoryGlobalStats < ReportBase
  def build
    data = {}
    data[l(:label_total_commits)]               = total_commits
    data[l(:label_total_contributors)]          = committers
    data[l(:label_first_commit_date)]           = format_date(first_commit.commit_date)
    data[l(:label_latest_commit_date)]          = format_date(last_commit.commit_date)
    data[l(:label_active_for)]                  = "#{active_for} #{l(:days, active_for)}"
    data[l(:label_average_commit_per_day)]      = average_commit_per_day
    data[l(:label_average_contributor_commits)] = average_contributor_commits
    data
  end

  private

  def total_commits
    @total_commits ||= all_changesets.count
  end

  def committers
    @committers ||= redmine_committers + external_committers
  end

  def first_commit
    @first_commit ||= all_changesets.order(commit_date: :asc).first
  end

  def last_commit
    @last_commit ||= all_changesets.order(commit_date: :asc).last
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
end
