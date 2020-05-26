# frozen_string_literal: true

# Administrative tags for an object
class AdministrativeTag < ApplicationRecord
  VALID_TAG_PATTERN = /\A.+( : .+)+\z/.freeze

  belongs_to :tag_label
end
