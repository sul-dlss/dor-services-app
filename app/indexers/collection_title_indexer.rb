# frozen_string_literal: true

class CollectionTitleIndexer
  attr_reader :cocina, :parent_collections

  def initialize(cocina:, parent_collections:, **)
    @cocina = cocina
    @parent_collections = parent_collections
  end

  # @return [Hash] the partial solr document for identifiable concerns
  def to_solr
    Rails.logger.debug { "In #{self.class}" }

    {}.tap do |solr_doc|
      parent_collections.each do |related_obj|
        coll_title = Cocina::Models::Builders::TitleBuilder.build(related_obj.description.title)

        # create/append collection_title_tesim and collection_title_ssim
        ::Solrizer.insert_field(solr_doc, 'collection_title', coll_title, :stored_searchable, :symbol)
      end
    end
  end
end
