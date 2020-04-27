module ViewHelpers
  class << self
    def time_ago(created_at)
      created_time = created_at
      current_time = Time.now.utc.to_i
      minutes_time = current_time - 5_400 # 90 minutes
      hours_time = current_time - 129_600 # 36 hours

      if created_time > minutes_time
        minutes = (current_time - created_time) / 60
        "#{plural(minutes, 'minute')} ago"
      elsif created_time > hours_time
        hours = (current_time - created_time) / 60 / 60
        "#{plural(hours, 'hour')} ago"
      else
        days = (current_time - created_time) / 60 / 60 / 24
        "#{plural(days, 'day')} ago"
      end
    end

    def plural(count, singular, plural = nil)
      if count == 1
        "1 #{singular}"
      elsif plural
        "#{count} #{plural}"
      else
        "#{count} #{singular}s"
      end
    end
  end
end
