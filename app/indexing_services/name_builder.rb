# frozen_string_literal: true

class NameBuilder
  # @param [Symbol] strategy ":first" is the strategy for how to choose a name if primary and display name is not found
  # @return [Array<String>] names
  def self.build_all(cocina_contributors)
    flat_names = cocina_contributors.filter_map { |cocina_contributor| flat_names_for(cocina_contributor) }.flatten
    flat_names.filter_map { |name| build_name(name) }
  end

  # @param [Symbol] strategy ":first" is the strategy for how to choose a name if primary and display name is not found
  # @return [String] name
  def self.build_primary_name(names, strategy: :first)
    names = Array(names) unless names.is_a?(Array)
    flat_names = flat_names_for(names)
    name = display_name_for(flat_names) || primary_name_for(flat_names)
    name ||= flat_names.first if strategy == :first
    return build_name(name) if name

    flat_names.filter_map { |one| build_name(one) }.first
  end

  def self.build_name(name)
    if name.groupedValue.present?
      name.groupedValue.find { |grouped_value| grouped_value.type == 'name' }&.value
    elsif name.structuredValue.present?
      name_part = joined_name_parts(name, 'name', '. ').presence
      surname = joined_name_parts(name, 'surname', ' ')
      forename = joined_name_parts(name, 'forename', ' ')
      terms_of_address = joined_name_parts(name, 'term of address', ', ')
      life_dates = joined_name_parts(name, 'life dates', ', ')
      activity_dates = joined_name_parts(name, 'activity dates', ', ')
      joined_name = name_part || join_parts([surname, forename], ', ')
      joined_name = join_parts([joined_name, terms_of_address], ' ')
      joined_name = join_parts([joined_name, life_dates], ', ')
      join_parts([joined_name, activity_dates], ', ')
    else
      name.value
    end
  end

  def self.display_name_for(names)
    names.find { |name| name.type == 'display' }
  end

  def self.primary_name_for(names)
    names.find { |name| name.status == 'primary' }
  end

  def self.flat_names_for(names)
    names.flat_map { |name| name.parallelValue.presence || name }
  end

  def self.joined_name_parts(name, type, joiner)
    join_parts(name.structuredValue.select { |structured_value| structured_value.type == type }.map(&:value), joiner)
  end

  def self.join_parts(parts, joiner)
    parts.compact_blank.join(joiner)
  end
end
