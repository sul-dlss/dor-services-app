# frozen_string_literal: true

# Show the relationships that are publically available
class PublishedRelationshipsFilter
  # @param [Cocina::Models::DRO] cocina_object
  def initialize(cocina_object)
    @cocina_object = cocina_object
  end

  def xml
    <<~XML
      <?xml version="1.0"?>
      <rdf:RDF xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description rdf:about="info:fedora/#{cocina_object.externalIdentifier}">
          #{collections}
          #{virtual_objects}
        </rdf:Description>
      </rdf:RDF>
    XML
  end

  private

  attr_reader :cocina_object

  INDENT = "\n      "

  def collections
    return unless cocina_object.dro?

    Array(cocina_object.structural&.isMemberOf).map do |collection_id|
      "<fedora:isMemberOfCollection rdf:resource=\"info:fedora/#{collection_id}\"/>"
    end.join(INDENT)
  end

  def virtual_objects
    return unless cocina_object.dro?

    VirtualObject.for(druid: cocina_object.externalIdentifier).map do |solr_doc|
      "<fedora:isConstituentOf rdf:resource=\"info:fedora/#{solr_doc.fetch(:id)}\"/>"
    end.join(INDENT)
  end
end
