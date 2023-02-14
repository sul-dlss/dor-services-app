# frozen_string_literal: true

# Reader from Folio's JSON API to fetch marc json given a HRID
class FolioReader
  attr_reader :folio_instance_hrid

  def initialize(folio_instance_hrid: nil)
    @folio_instance_hrid = folio_instance_hrid
  end

  # @return [MARC::Record]
  # @raises FolioClient::UnexpectedResponse::ResourceNotFound, and FolioClient::UnexpectedResponse::MultipleResourcesFound
  def to_marc
    MARC::Record.new_from_hash(FolioClient.fetch_marc_hash(instance_hrid: folio_instance_hrid))
  end
end
