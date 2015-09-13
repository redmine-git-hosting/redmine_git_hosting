module ReportHelper
  unloadable

  def date_to
    Date.today
  end


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

end
