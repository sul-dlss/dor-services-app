# frozen_string_literal: true

# Administrative tags for an object
class AdministrativeTag < ApplicationRecord
  VALID_TAG_PATTERN = /\A.+( : .+)+\z/.freeze

  validates :tag, format: {
    with: VALID_TAG_PATTERN,
    message: 'must be a series of 2 or more strings delimited with space-padded colons, e.g., "Registered By : mjgiarlo : now"'
  }, uniqueness: {
    scope: :druid,
    message: 'has already been assigned to the given druid (no duplicate tags for a druid)'
  }
end
