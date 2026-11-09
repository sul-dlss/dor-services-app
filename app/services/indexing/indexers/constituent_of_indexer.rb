# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes the virtual objects that an object is a constituent of
    class ConstituentOfIndexer
      attr_reader :parent_virtual_objects

      def initialize(parent_virtual_objects:, **)
        @parent_virtual_objects = parent_virtual_objects
      end

      # @return [Hash] the partial solr document for constituent of concerns
      def to_solr
        return {} if title_druids.empty?

        { 'is_constituent_of_title_druid_ssimdv' => title_druids }
      end

      private

      def title_druids
        @title_druids ||= parent_virtual_objects.filter_map do |virtual_object|
          title = Cocina::Models::Builders::TitleBuilder.build(virtual_object.description.title)
          Indexing::CompositeFacetValue.build(label: title, id: virtual_object.externalIdentifier) if title.present?
        end
      end
    end
  end
end
