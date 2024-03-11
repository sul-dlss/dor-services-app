# frozen_string_literal: true

# Administrative tags for an object
class AdministrativeTag < ApplicationRecord
  belongs_to :tag_label
end
