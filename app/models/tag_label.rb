# frozen_string_literal: true

# This stores the tag text. This text could be applied to more than one object by an AdministrativeTag
class TagLabel < ApplicationRecord
  VALID_TAG_PATTERN = /\A.+( : .+)+\z/.freeze
  has_many :administrative_tags, dependent: :destroy

  validates :tag, format: {
    with: VALID_TAG_PATTERN,
    message: 'must be a series of 2 or more strings delimited with space-padded colons, e.g., "Registered By : mjgiarlo : now"'
  }

  scope :content_type, -> { where('tag like ?', 'Process : Content Type : %') }
  scope :project, -> { where('tag like ?', 'Project : %') }
end
