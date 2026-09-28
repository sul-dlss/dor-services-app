# frozen_string_literal: true

module Indexing
  # Builds the composite "<label>:<id>" values indexed for facets, e.g., "<title>:<druid>"
  # for the APO and Collection facets and "<label>:<uri>" for the license facet.
  # Read on the argo-b3 side by Search::CompositeFacetValue,
  # which parses this same format back into a label and an id.
  # This allows us to facet on the id when searching but display the label in the facet.
  # The composite facet value generated here and argo-b3's parsing of it need to remain in sync.
  # see https://github.com/sul-dlss/argo-b3/issues/530
  class CompositeFacetValue
    def self.build(label:, id:)
      "#{label}:#{id}"
    end
  end
end
