# frozen_string_literal: true

# Extracts useful text for searching from Cocina Description
class AllSearchTextBuilder
  def self.build(cocina_description)
    new(cocina_description).build
  end

  def initialize(cocina_description)
    @cocina_description = cocina_description
  end

  def build
    @text = []
    recurse(cocina_description)
    text.join(' ')
  end

  private

  attr_reader :cocina_description, :text

  # this originally had displayLabel, but Arcadia recommends against it
  TEXT_KEYS = %i[
    value
  ].freeze

  RECURSE_KEYS = %i[
    structuredValue
    parallelValue
    groupedValue
    title
    contributor
    event
    form
    language
    note
    relatedResource
    subject
    name
    location
  ].freeze

  def recurse(desc)
    TEXT_KEYS.each do |key|
      value = desc.try(key)
      text << value if value.present?
    end

    RECURSE_KEYS.each do |key|
      Array(desc.try(key)).each { |value| recurse(value) }
    end
  end
end
