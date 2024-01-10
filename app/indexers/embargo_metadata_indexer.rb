# frozen_string_literal: true

class EmbargoMetadataIndexer
  attr_reader :cocina

  def initialize(cocina:, **)
    @cocina = cocina
  end

  # These fields are used by the EmbargoReleaseService in dor-services-app
  # @return [Hash] the partial solr document for embargoMetadata
  def to_solr
    {}.tap do |solr_doc|
      embargo_release_date = embargo_release_date(cocina)
      if embargo_release_date.present?
        solr_doc['embargo_status_ssim'] = ['embargoed']
        solr_doc['embargo_release_dtsim'] = [embargo_release_date.utc.iso8601]
      end
    end
  end

  private

  def embargo_release_date(cocina)
    cocina.access.embargo.releaseDate if cocina.access.embargo&.releaseDate.present?
  end
end
