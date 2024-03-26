# frozen_string_literal: true

# Stores information about releasing an object to be discoverable by the public.
class ReleaseTag < ApplicationRecord
  enum :what, %i[self collection].index_with(&:to_s), validate: true

  def self.from_cocina(druid:, tag:)
    attributes = tag.to_h.merge(druid:)
    attributes[:released_to] = attributes.delete(:to)
    attributes[:created_at] = attributes.delete(:date)
    new(attributes)
  end
end
