# frozen_string_literal: true

class PublisherNameBuilder
  def self.build(events)
    roles = publisher_roles(events)

    publisher_names_for(roles)
  end

  def self.publisher_roles(events)
    contributors = events.flat_map(&:contributor).compact
    return [] if contributors.blank?

    contributors.select { |contributor| Array(contributor.role).any? { |role| role.value&.downcase == 'publisher' } }
  end

  # Returns the primary publisher if available.
  def self.publisher_names_for(publisher_roles)
    return if publisher_roles.blank?

    primary_publisher = publisher_roles.find { |role| role.status == 'primary' }

    return contributor_name(primary_publisher).first if primary_publisher

    publisher_roles.flat_map { |contributor| contributor_name(contributor) }.join(' : ')
  end

  def self.contributor_name(contributor)
    contributor.name.flat_map { |name| flat_name(name) }
  end

  def self.flat_name(value)
    primary_name = value.parallelValue&.find { |role| role.status == 'primary' }
    return parallel_name(value.parallelValue) if !primary_name && value.parallelValue.present?

    return name_for(primary_name) if primary_name

    name_for(value)
  end

  def self.name_for(name)
    name.structuredValue.present? ? name.structuredValue.map(&:value).join('. ') : name.value
  end

  def self.parallel_name(names)
    names.map { |single_name| name_for(single_name) }.join(' : ')
  end
end
