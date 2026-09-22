# frozen_string_literal: true

module Indexing
  # Builds the composite "<label>:<druid>" values indexed for the APO and
  # Collection facets. Read on the argo-b3 side by Search::CompositeFacetValue,
  # which parses this same format back into a label and a druid.
  # This allows us to facet on druid when searching but display the title in the facet.
  # The composite facet value generated here and argo-b3's parsing of it need to remain in sync.
  # see https://github.com/sul-dlss/argo-b3/issues/530
  class CompositeFacetValue
    def self.build(label:, druid:)
      "#{label}:#{druid}"
    end
  end
end
