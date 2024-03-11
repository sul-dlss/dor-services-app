# frozen_string_literal: true

# This stores the tag text. This text could be applied to more than one object by an AdministrativeTag
class TagLabel < ApplicationRecord
  VALID_TAG_PATTERN = /\A.+( : .+)+\z/

  has_many :administrative_tags, dependent: :destroy
  normalizes :tag, with: ->(tag) { tag.squish }
  scope :project, -> { where('tag like ?', 'Project : %') }
  validates :tag, format: {
    with: VALID_TAG_PATTERN,
    message: 'must be a series of 2 or more strings delimited with space-padded colons, e.g., "Registered By : mjgiarlo : now"' # rubocop:disable Rails/I18nLocaleTexts
  }
end
