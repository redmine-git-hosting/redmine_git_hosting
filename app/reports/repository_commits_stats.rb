class RepositoryCommitsStats < ReportBase

  def commits_per_month
    data = {}
    data[:categories] = months.reverse
    data[:series]     = []
    data[:series] << { name: l(:label_commit_plural), data: total_commits_by_month[0..11].reverse }
    data[:series] << { name: l(:label_change_plural), data: total_changes_by_month[0..11].reverse }
    data
  end


  def commits_per_day
    data = {}
    data[:categories] = total_commits_by_day.keys
    data[:series]     = []
    data[:series] << { name: l(:label_commit_plural), data: total_commits_by_day.values }
    data[:series] << { name: l(:label_change_plural), data: total_changes_by_day.values }
    data
  end


  def commits_per_hours
    data = {}
    data[:categories] = hours
    data[:series]     = []
    data[:series] << { name: l(:label_commit_plural), data: total_commits_by_hour }
    data
  end


  def commits_per_weekday
    data = {}
    data[:name] = l(:label_commit_plural)
    data[:data] = []
    total_commits_by_weekday.each do |key, value|
      data[:data] << [key, value]
    end
    [data]
  end


  private


    def total_commits_by_month
      total_by_month_for(:commits_by_day)
    end


    def total_changes_by_month
      total_by_month_for(:changes_by_day)
    end


    def total_commits_by_day
      @total_commits_by_day ||= all_commits_by_day.order(:commit_date).count
    end


    def total_changes_by_day
      return @total_changes_by_day if !@total_changes_by_day.nil?
      @total_changes_by_day = nil
      changes = {}
      Changeset.where('repository_id = ?', repository.id).includes(:filechanges).order(:commit_date).each do |changeset|
        changes[changeset.commit_date] = 0 if !changes.has_key?(changeset.commit_date)
        changes[changeset.commit_date] += changeset.filechanges.size
      end
      @total_changes_by_day = changes
      @total_changes_by_day
    end


    def total_commits_by_hour
      total_by_hour_for(:commits_by_hour)
    end


    def total_commits_by_weekday
      week_day = week_day_hash
      commits_by_day.each do |commit_date, commit_count|
        case commit_date.to_date.wday
        when 0
          week_day[l(:label_sunday)] += commit_count
        when 1
          week_day[l(:label_monday)] += commit_count
        when 2
          week_day[l(:label_tuesday)] += commit_count
        when 3
          week_day[l(:label_wednesday)] += commit_count
        when 4
          week_day[l(:label_thursday)] += commit_count
        when 5
          week_day[l(:label_friday)] += commit_count
        when 6
          week_day[l(:label_saturday)] += commit_count
        end
      end
      week_day
    end

end
