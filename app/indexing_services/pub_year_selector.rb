# frozen_string_literal: true

# Finds the pub date to index from events
class PubYearSelector
  # @param [Array<Cocina::Models::Events>] events
  # @return [String] the year value for Solr
  def self.build(events)
    new(events).build
  end

  def initialize(events)
    @events = events
  end

  def build
    date = find_date
    ParseDate.earliest_year(date).to_s if date.present?
  end

  # rubocop:disable Metrics/PerceivedComplexity
  def find_date
    primary_date(events) ||
      EventDateBuilder.build(production_event, 'production') ||
      EventDateBuilder.build(publication_event, 'publication') ||
      EventDateBuilder.build(capture_event, 'capture') ||
      EventDateBuilder.build(copyright_event, 'copyright') ||
      creation_date ||
      first_date ||
      structured_dates(events) ||
      find_date_in_parallel_events
  end
  # rubocop:enable Metrics/PerceivedComplexity

  private

  attr_reader :events

  def find_date_in_parallel_events
    parallel_events = events.flat_map(&:parallelEvent).compact
    primary_date(parallel_events) ||
      structured_dates(parallel_events)
  end

  def primary_date(eligible_events)
    dates = eligible_events.flat_map(&:date).compact
    return if dates.blank?

    dates.find { |date| date.status == 'primary' }&.value
  end

  def first_date
    dates = events.flat_map(&:date).compact
    return if dates.blank?

    date_value(dates.first)
  end

  def date_value(date)
    return date.value if date.value
    return if date.parallelValue.blank?

    primary = date.parallelValue.find { |val| val.status == 'primary' }
    return primary.value if primary

    structured_values = date.parallelValue.first.structuredValue
    return find_within_structured_values(structured_values) if structured_values.present?

    date.parallelValue.first.value
  end

  def structured_dates(eligible_events)
    dates = eligible_events.flat_map(&:date).compact
    return if dates.blank?

    structured_values = dates.first.structuredValue
    return if structured_values.blank?

    find_within_structured_values(structured_values)
  end

  def find_within_structured_values(structured_values)
    primary = structured_values.find { |date| date.status == 'primary' }
    return primary.value if primary

    structured_values.first.value
  end

  def creation_date
    @creation_date ||= EventDateBuilder.build(creation_event, 'creation')
  end

  def publication_event
    @publication_event ||= EventSelector.select(events, 'publication')
  end

  def creation_event
    @creation_event ||= EventSelector.select(events, 'creation')
  end

  def capture_event
    @capture_event ||= EventSelector.select(events, 'capture')
  end

  def copyright_event
    @copyright_event ||= EventSelector.select(events, 'copyright')
  end

  def production_event
    @production_event ||= EventSelector.select(events, 'production')
  end
end
