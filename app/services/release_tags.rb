# frozen_string_literal: true

# Shows and creates release tags. This replaces parts of https://github.com/sul-dlss/dor-services/blob/main/lib/dor/models/concerns/releaseable.rb
class ReleaseTags
  # Retrieve the release tags for an item and all the collections that it is a part of
  #
  # @param cocina_object [Cocina::Models::DRO, Cocina::Models::Collection] the object to list release tags for
  # @return [Hash] (see Dor::ReleaseTags::IdentityMetadata.released_for)
  def self.for(cocina_object:)
    IdentityMetadata.for(cocina_object).released_for({})
  end
end
