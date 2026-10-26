class CalendarService
  Occurrence = Struct.new(:event_id, :original_start, :name, :description,
                          :start_timestamp, :end_timestamp, :all_day, :recurring,
                          :recurrence_until, :attendee_ids, :created_by, :household_id,
                          keyword_init: true)

  def events_for(household, from:, to:, user_id: nil)
    events = household.events
    if user_id.present?
      events = events.left_joins(:event_attendees)
                     .where("event_attendees.user_id = ? OR NOT EXISTS (SELECT 1 FROM event_attendees ea WHERE ea.event_id = events.event_id)",
                            user_id)
                     .distinct
    end
    events = events.where("start_timestamp <= ?", to)
                   .where("recurring = 'NONE' AND end_timestamp >= ? OR recurring <> 'NONE' AND (recurrence_until IS NULL OR recurrence_until >= ?)",
                          from, from.to_date)
                   .includes(:event_attendees, :event_exceptions)

    events.flat_map { |event| expand(event, from, to) }
          .sort_by { |occurrence| [occurrence.start_timestamp, occurrence.event_id] }
  end

  def occurrence?(event, original_start)
    return event.start_timestamp == original_start if event.recurring == "NONE"

    recurrence_times(event, original_start, original_start).include?(original_start)
  end

  private

  def expand(event, from, to)
    return [] if event.recurring == "NONE" && (event.end_timestamp < from || event.start_timestamp > to)

    duration = event.end_timestamp - event.start_timestamp
    exceptions = event.event_exceptions.index_by(&:original_start)
    timestamps = if event.recurring == "NONE"
                   [event.start_timestamp]
                 else
                   recurrence_times(event, from - duration, to)
                 end

    exceptions.each_value do |exception|
      next if exception.is_cancelled || exception.start_timestamp.nil?

      exception_end = exception.end_timestamp || exception.start_timestamp + duration
      if exception_end >= from && exception.start_timestamp <= to &&
         occurrence?(event, exception.original_start)
        timestamps << exception.original_start
      end
    end

    timestamps.uniq.filter_map do |original_start|
      exception = exceptions[original_start]
      next if exception&.is_cancelled

      start_time = exception&.start_timestamp || original_start
      end_time = exception&.end_timestamp || original_start + duration
      next if end_time < from || start_time > to

      Occurrence.new(
        event_id: event.id,
        original_start:,
        name: exception&.name || event.name,
        description: exception&.description || event.description,
        start_timestamp: start_time,
        end_timestamp: end_time,
        all_day: event.all_day,
        recurring: event.recurring,
        recurrence_until: event.recurrence_until,
        attendee_ids: event.event_attendees.map(&:user_id),
        created_by: event.created_by,
        household_id: event.household_id
      )
    end
  end

  def recurrence_times(event, from, to)
    return [] if to < event.start_timestamp || recurrence_expired?(event, from)

    duration = event.end_timestamp - event.start_timestamp
    first_relevant = [from, event.start_timestamp].max
    target_start = first_relevant - duration
    index = recurrence_index(event, target_start)
    time = occurrence_at_index(event, index)
    while index.positive? && occurrence_at_index(event, index - 1) >= target_start
      index -= 1
      time = occurrence_at_index(event, index)
    end
    time = occurrence_at_index(event, index + 1) while time < target_start

    occurrences = []
    while time <= to && within_recurrence_end?(event, time)
      occurrences << time if time >= target_start
      index += 1
      time = occurrence_at_index(event, index)
    end
    occurrences
  end

  def recurrence_index(event, time)
    case event.recurring
    when "DAILY"
      [(time.to_date - event.start_timestamp.to_date).to_i, 0].max
    when "WEEKLY"
      [((time.to_date - event.start_timestamp.to_date).to_i / 7), 0].max
    when "MONTHLY"
      [((time.year - event.start_timestamp.year) * 12 + time.month - event.start_timestamp.month), 0].max
    else
      0
    end
  end

  def occurrence_at_index(event, index)
    case event.recurring
    when "DAILY" then event.start_timestamp + index.days
    when "WEEKLY" then event.start_timestamp + (index * 7).days
    when "MONTHLY" then event.start_timestamp.advance(months: index)
    else event.start_timestamp
    end
  end

  def within_recurrence_end?(event, time)
    event.recurrence_until.nil? || time.to_date <= event.recurrence_until
  end

  def recurrence_expired?(event, time)
    event.recurrence_until.present? && time.to_date > event.recurrence_until
  end
end