module ReportQuery
  private

  def all_changesets
    @all_changesets ||= Changeset.where(repository_id: repository.id)
  end

  def all_changes
    @all_changes ||= Change.joins(:changeset).where("#{Changeset.table_name}.repository_id = ?", repository.id)
  end

  def all_commits_by_day
    @all_commits_by_day ||= all_changesets.group(:commit_date)
  end

  def all_changes_by_day
    @all_changes_by_day ||= all_changes.group(:commit_date)
  end

  def redmine_committers
    @redmine_committers ||= all_changesets.where.not(user_id: nil).distinct.count(:user_id)
  end

  def external_committers
    @external_committers ||= all_changesets.where(user_id: nil).distinct.count(:committer)
  end

  def commits_by_day
    @commits_by_day ||= all_commits_by_day.count
  end

  def changes_by_day
    @changes_by_day ||= all_changes_by_day.count
  end

  def commits_by_hour
    @commits_by_hour ||= all_changesets.map(&:committed_on)
  end

  def commits_by_author
    @commits_by_author ||= all_changesets.group(:committer).count
  end

  def changes_by_author
    @changes_by_author ||= all_changes.group(:committer).count
  end
end
