class RepositoryCommitsStats

  include Redmine::I18n

  attr_reader :repository


  def initialize(repository)
    @repository = repository
  end


  def commits_per_month
    date_to = Date.today

    commits_by_month = [0] * 12
    commits_by_day.each { |c| commits_by_month[(date_to.month - c.first.to_date.month) % 12] += c.last }

    changes_by_month = [0] * 12
    changes_by_day.each {|c| changes_by_month[(date_to.month - c.first.to_date.month) % 12] += c.last }

    fields = []
    12.times {|m| fields << month_name(((Date.today.month - 1 - m) % 12) + 1)}

    data = {}
    data[:categories] = fields.reverse
    data[:series] = []
    data[:series].push({name: l(:label_commit_plural), data: commits_by_month[0..11].reverse})
    data[:series].push({name: l(:label_change_plural), data: changes_by_month[0..11].reverse})

    data
  end


  def commits_per_day
    data = {}
    data[:categories]    = total_commits_by_day.keys
    data[:series]        = []
    data[:series].push({name: l(:label_commit_plural), data: total_commits_by_day.values})
    data[:series].push({name: l(:label_change_plural), data: total_changes_by_day.values})
    data
  end


  def commits_per_hours
    total_commits_by_hour = Changeset.where("repository_id = ?", repository.id).map(&:committed_on)

    commits_by_hour = [0] * 24
    total_commits_by_hour.each {|c| commits_by_hour[get_hour_from_date(c)] += 1 }

    hours = (0..23).step(1).to_a
    new_hours = []
    hours.each { |h| new_hours.push("#{h}h") }

    data = {}
    data[:categories]    = new_hours
    data[:series]        = []
    data[:series].push({:name => l(:label_commit_plural), :data => commits_by_hour})

    return data
  end


  def commits_per_weekday
    week_day = {}
    week_day[l(:label_monday)]    = 0
    week_day[l(:label_tuesday)]   = 0
    week_day[l(:label_wednesday)] = 0
    week_day[l(:label_thursday)]  = 0
    week_day[l(:label_friday)]    = 0
    week_day[l(:label_saturday)]  = 0
    week_day[l(:label_sunday)]    = 0

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

    data = {}
    data[:name] = l(:label_commit_plural)
    data[:data] = []

    week_day.each do |key, value|
      data[:data].push([key, value])
    end

    return [data]
  end


  private


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
      @total_changes_by_day ||= Change.joins(:changeset).where("#{Changeset.table_name}.repository_id = ?", repository.id).group(:commit_date).order(:commit_date).count
    end


    def total_commits
      @total_commits ||= Changeset.where("repository_id = ?", repository.id).group(:commit_date).count
    end

end
