# frozen_string_literal: true

class TopicBuilder
  # @param [Array] subjects
  # @param [String] filter can either be 'topic' or 'name'
  def self.build(subjects, filter:, remove_trailing_punctuation: false)
    new(filter:, remove_trailing_punctuation:).build(subjects)
  end

  def initialize(filter:, remove_trailing_punctuation:)
    @filter = filter
    @remove_trailing_punctuation = remove_trailing_punctuation
  end

  def build(subjects)
    topics(subjects).flat_map { |topic| flat_topic(topic) }.compact.uniq
  end

  private

  attr_reader :filter

  def remove_trailing_punctuation?
    @remove_trailing_punctuation
  end

  # Filter the subjects we are interested in>
  # Handles:
  # parallelValue that contain structuredValue and the parallelValue has the type AND
  # parallelValue that contain structuredValue each with their own type AND
  # parallelValue that has a type conferred to the child AND
  # structuredValue that contains structuredValue where the type can be at the higher or lower level.
  def topics(subjects)
    (
      subjects.flat_map { |subject| basic_value(subject) } +
      subjects.flat_map { |subject| structured_values(subject) } +
      parallel_subjects(subjects)
    ).compact
  end

  def parallel_subjects(subjects)
    parallels = subjects.select(&:parallelValue)
    parallels.flat_map { |subject| parallel_with_type(subject, subject.type) if subject.type } +
      parallels.flat_map { |subject| topics(subject.parallelValue) unless subject.type }
  end

  def flat_topic(value)
    if value.parallelValue.present?
      value.parallelValue.flat_map { |topic| flat_topic(topic) }
    elsif remove_trailing_punctuation?
      # comma, semicolon, and backslash are dropped
      Array(value.value&.sub(/[ ,;\\]+$/, ''))
    else
      Array(value.value)
    end
  end

  def parallel_with_type(item, type_from_parent)
    return unless type_matches_filter?(type_from_parent)

    item
  end

  def basic_value(subject)
    return create_fullname(subject) if filter == 'name' && subject.type == 'person'
    return create_title(subject) if filter == 'name' && subject.type == 'title'

    subject if type_matches_filter?(subject.type)
  end

  def structured_values(subject)
    selected = Array(subject.structuredValue).select { |child| type_matches_filter?(child.type) }

    topics(selected)
  end

  def create_title(title)
    titles = Cocina::Models::Builders::TitleBuilder.build([title], strategy: :all, add_punctuation: false)
    titles.map { |value| Cocina::Models::DescriptiveValue.new(value:) }
  end

  def create_fullname(name)
    names = NameBuilder.build([name], strategy: :all)
    names.map { |value| Cocina::Models::DescriptiveValue.new(value:) }
  end

  def type_matches_filter?(type)
    (filter == 'name' && %w[person organization title occupation].include?(type)) ||
      type == filter
  end
end
