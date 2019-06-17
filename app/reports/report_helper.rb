module ReportHelper
  def date_to
    User.current.today
  end

  def week_day_hash
    { day_name(1) => 0,
      day_name(2) => 0,
      day_name(3) => 0,
      day_name(4) => 0,
      day_name(5) => 0,
      day_name(6) => 0,
      day_name(0) => 0 }
  end

  def hours
    (0..23).step(1).map { |h| "#{h}h" }
  end

  def months
    (1..12).map { |m| l('date.month_names')[m].capitalize }
  end

  def get_hour_from_date(date)
    return nil unless date

    time = date.to_time
    zone = User.current.time_zone
    local = zone ? time.in_time_zone(zone) : (time.utc? ? time.localtime : time)
    local.hour
  end

  def total_by_month_for(method)
    total = [0] * 12
    send(method).each { |c| total[(date_to.month - c.first.to_date.month) % 12] += c.last }
    total
  end

  def total_by_hour_for(method)
    total = [0] * 24
    send(method).each { |c| total[get_hour_from_date(c)] += 1 }
    total
  end
end
