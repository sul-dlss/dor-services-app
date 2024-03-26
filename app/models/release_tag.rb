# frozen_string_literal: true

# Model for release tags, which indicate that an item or collection should be released.
class ReleaseTag < ApplicationRecord
  default_scope { order(created_at: :asc) }
end
