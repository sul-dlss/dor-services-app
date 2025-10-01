# frozen_string_literal: true

# Shows and creates release tags. This replaces parts of https://github.com/sul-dlss/dor-services/blob/main/lib/dor/models/concerns/releaseable.rb
class ReleaseTagService
  # Retrieve the release tags for an item
  def self.tags(druid:)
    ReleaseTag.where(druid:).map(&:to_cocina)
  end

  # Creates ReleaseTag model objects.
  # @param [Dor::ReleaseTag] tag
  def self.create(druid:, tag:)
    ReleaseTag.from_cocina(druid:, tag:).save!
  end
end
