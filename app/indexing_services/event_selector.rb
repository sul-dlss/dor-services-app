# frozen_string_literal: true

class EventSelector
  # @param [Array<Cocina::Models::Event>] events
  # @param [String] desired_date_type a string to match the date.type in a Cocina::Models::Event
  # @return [Cocina::Models::Event, nil] event best matching selected
  def self.select(events, desired_date_type)
    date_type_matches_and_primary(events, desired_date_type) ||
      date_and_event_type_match(events, desired_date_type) ||
      event_type_matches_but_no_date_type(events, desired_date_type) ||
      event_has_date_type(events, desired_date_type)
  end

  # @param [Cocina::Models::DescriptiveValue] a date object from an event
  # @return [Boolean] true if date.status == primary
  def self.date_status_primary(date)
    structured_primary = Array(date.structuredValue).find do |structured_date|
      structured_date.status == 'primary'
    end

    parallel_value_primary = Array(date.parallelValue).find do |parallel_value|
      parallel_value.status == 'primary'
    end

    date.status == 'primary' || structured_primary || parallel_value_primary
  end

  # @return [Cocina::Models::Event, nil] event with date of type desired_date_type and of status primary
  def self.date_type_matches_and_primary(events, desired_date_type)
    events.find do |event|
      event_dates = Array(event.date) + Array(event.parallelEvent&.map(&:date))
      event_dates.flatten.compact.find do |date|
        next if desired_date_type != date_type(date)

        date_status_primary(date)
      end
    end
  end
  private_class_method :date_type_matches_and_primary

  # @return [Cocina::Models::Event, nil] event with date of type desired_date_type and the event has matching type
  def self.date_and_event_type_match(events, desired_date_type)
    events.find do |event|
      next unless event_type_matches(event, desired_date_type)

      event_dates = Array(event.date) + Array(event.parallelEvent&.map(&:date))
      event_dates.flatten.compact.find do |date|
        desired_date_type == date_type(date)
      end
    end
  end
  private_class_method :date_and_event_type_match

  # @return [Cocina::Models::Event, nil] event with type of desired_date_type and a date field without a type
  def self.event_type_matches_but_no_date_type(events, desired_date_type)
    events.find do |event|
      next unless event_type_matches(event, desired_date_type)

      event_dates = Array(event.date) + Array(event.parallelEvent&.map(&:date))
      event_dates.flatten.compact.find do |date|
        date_type(date).nil?
      end
    end
  end
  private_class_method :event_type_matches_but_no_date_type

  # @return [Cocina::Models::Event, nil] event with date of type desired_date_type
  def self.event_has_date_type(events, desired_date_type)
    events.find do |event|
      event_dates = Array(event.date) + Array(event.parallelEvent&.map(&:date))
      event_dates.flatten.compact.find do |date|
        desired_date_type == date_type(date)
      end
    end
  end
  private_class_method :event_has_date_type

  # @return [Boolean] true if event type matches or parallelEvent type matches the param
  def self.event_type_matches(event, desired_type)
    return true if event.type == desired_type

    matching_event = event.parallelEvent&.find { |parallel_event| parallel_event.type == desired_type }
    matching_event.present?
  end
  private_class_method :event_type_matches

  # @param [Cocina::Models::DescriptiveValue] a date object from an event
  # @return [String, nil] type from date object
  # rubocop:disable Metrics/PerceivedComplexity
  def self.date_type(date)
    return date.type if date&.type.present?

    Array(date.structuredValue).find do |structured_value|
      return structured_value.type if structured_value&.type.present?
    end

    Array(date.parallelValue).find do |parallel_value|
      return parallel_value.type if parallel_value&.type.present?
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
  private_class_method :date_type
end
