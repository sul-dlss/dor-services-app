# frozen_string_literal: true

# Show the relationships that are publically available
class PublishedRelationshipsFilter
  # @param [Cocina::Models::DRO] cocina_object
  # @param [Array<Hash>] constituents a list of constituents (virtual object members) that are part of this object
  def initialize(cocina_object, constituents)
    @cocina_object = cocina_object
    @constituents = constituents
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

  attr_reader :cocina_object, :constituents

  INDENT = "\n      "

  def collections
    return unless cocina_object.dro?

    cocina_object.structural.isMemberOf.map do |collection_id|
      "<fedora:isMemberOfCollection rdf:resource=\"info:fedora/#{collection_id}\"/>"
    end.join(INDENT)
  end

  def virtual_objects
    return unless cocina_object.dro?

    constituents.map do |virtual_object_params|
      "<fedora:isConstituentOf rdf:resource=\"info:fedora/#{virtual_object_params.fetch(:id)}\"/>"
    end.join(INDENT)
  end
end
