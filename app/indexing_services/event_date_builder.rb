# frozen_string_literal: true

class EventDateBuilder
  # @param [Cocina::Models::Event] event single selected  event
  # @return [String, nil] the date value for Solr
  def self.build(event, date_type)
    event_dates = Array(event&.date) + Array(event&.parallelEvent&.map(&:date))

    matching_date_value_with_status_primary(event_dates, date_type) ||
      matching_date_value(event_dates, date_type) ||
      untyped_date_value(event_dates)
  end

  # @return [String, nil] date.value from a date of type of date_type and of status primary
  def self.matching_date_value_with_status_primary(event_dates, date_type)
    event_dates.flatten.compact.find do |date|
      next if date.type != date_type

      next unless EventSelector.date_status_primary(date)

      return date_value(date)
    end
  end
  private_class_method :matching_date_value_with_status_primary

  # @return [String, nil] date.value from a date of type of date_type
  def self.matching_date_value(event_dates, date_type)
    event_dates.flatten.compact.find do |date|
      next if date.type != date_type

      return date_value(date)
    end
  end
  private_class_method :matching_date_value

  # @return [String, nil] date.value from a date without a type
  def self.untyped_date_value(event_dates)
    event_dates.flatten.compact.find do |date|
      next if date.type.present?

      return date_value(date)
    end
  end
  private_class_method :untyped_date_value

  # @param [Cocina::Models::DescriptiveValue] a date object from an event
  # @return [String, nil] value from date object
  # rubocop:disable Metrics/PerceivedComplexity
  def self.date_value(date)
    return date.value if date&.value.present?

    Array(date&.structuredValue).find do |structured_value|
      return structured_value.value if structured_value&.value.present?
    end

    Array(date&.parallelValue).find do |parallel_value|
      return parallel_value.value if parallel_value&.value.present?
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
  private_class_method :date_value
end
