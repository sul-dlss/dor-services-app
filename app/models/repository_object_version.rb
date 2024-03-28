# frozen_string_literal: true

# Models a repository object as it looked at a particular version.
class RepositoryObjectVersion < ApplicationRecord
  belongs_to :repository_object

  validates :version, :label, :administrative, presence: true
end
