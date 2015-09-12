class RepositoryCommitsStats
  unloadable

  include Redmine::I18n

  attr_reader :repository
  attr_reader :date_to


  def initialize(repository)
    @repository = repository
    @date_to    = Date.today
  end


  def commits_per_month
    data = {}
    data[:categories] = months.reverse
    data[:series]     = []
    data[:series] << { name: l(:label_commit_plural), data: commits_by_month[0..11].reverse }
    data[:series] << { name: l(:label_change_plural), data: changes_by_month[0..11].reverse }
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
    data[:series] << { name: l(:label_commit_plural), data: commits_by_hour }
    data
  end


  def commits_per_weekday
    data = {}
    data[:name] = l(:label_commit_plural)
    data[:data] = []
    commits_by_weekday.each do |key, value|
      data[:data] << [key, value]
    end
    [data]
  end


  private


    def week_day_hash
       {
        l(:label_monday)    => 0,
        l(:label_tuesday)   => 0,
        l(:label_wednesday) => 0,
        l(:label_thursday)  => 0,
        l(:label_friday)    => 0,
        l(:label_saturday)  => 0,
        l(:label_sunday)    => 0
      }
    end


    def hours
      (0..23).step(1).map { |h| "#{h}h" }
    end


    def months
      (1..12).map { |m| l("date.month_names")[m].capitalize }
    end


    def get_hour_from_date(date)
      return nil unless date
      time = date.to_time
      zone = User.current.time_zone
      local = zone ? time.in_time_zone(zone) : (time.utc? ? time.localtime : time)
      local.hour
    end


    def commits_by_day
      @commits_by_day ||= Changeset.where("repository_id = ?", repository.id).group(:commit_date).count
    end


    def changes_by_day
      @changes_by_day ||= Change.joins(:changeset).where("#{Changeset.table_name}.repository_id = ?", repository.id).group(:commit_date).count
    end


    def total_commits_by_day
      @total_commits_by_day ||= Changeset.where("repository_id = ?", repository.id).group(:commit_date).order(:commit_date).count
    end


    def total_changes_by_day
      return @total_changes_by_day if !@total_changes_by_day.nil?
      @total_changes_by_day = nil
      changes = {}
      Changeset.where("repository_id = ?", repository.id).includes(:filechanges).order(:commit_date).each do |changeset|
        changes[changeset.commit_date] = 0 if !changes.has_key?(changeset.commit_date)
        changes[changeset.commit_date] += changeset.filechanges.size
      end
      @total_changes_by_day = changes
      @total_changes_by_day
    end


    def total_commits
      @total_commits ||= Changeset.where("repository_id = ?", repository.id).group(:commit_date).count
    end


    def total_commits_by_hour
      @total_commits_by_hour ||= Changeset.where("repository_id = ?", repository.id).map(&:committed_on)
    end


    def commits_by_month
      cbm = [0] * 12
      commits_by_day.each { |c| cbm[(date_to.month - c.first.to_date.month) % 12] += c.last }
      cbm
    end


    def changes_by_month
      cbm = [0] * 12
      changes_by_day.each { |c| cbm[(date_to.month - c.first.to_date.month) % 12] += c.last }
      cbm
    end


    def commits_by_hour
      cbh = [0] * 24
      total_commits_by_hour.each { |c| cbh[get_hour_from_date(c)] += 1 }
      cbh
    end


    def commits_by_weekday
      week_day = week_day_hash
      total_commits.each do |commit_date, commit_count|
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
