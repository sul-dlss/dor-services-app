# frozen_string_literal: true

# Administrative tags for an object
class AdministrativeTag < ApplicationRecord
  VALID_TAG_PATTERN = /\A.+( : .+)+\z/.freeze

  belongs_to :tag_label

  validates :tag_label_id, uniqueness: {
    scope: :druid,
    message: 'has already been assigned to the given druid (no duplicate tags for a druid)'
  }
end
