# frozen_string_literal: true

module Publish
  # Exports the full object XML that we display on purl.stanford.edu
  class PublicXmlService
    # @param [Cocina::Models::DRO, Cocina::Models::Collection] public_cocina a cocina object stripped of non-public data
    # @param [Hash{String => Boolean}] released_for keys are Project name strings, values are boolean
    # @param [ThumbnailService] thumbnail_service
    def initialize(public_cocina:, released_for:, thumbnail_service:)
      @public_cocina = public_cocina
      @released_for = released_for
      @thumbnail_service = thumbnail_service
    end

    # @raise [Dor::DataError]
    # rubocop:disable Metrics/AbcSize
    # @params [Hash] _opts ({}) Rails sends args when rendering XML but we ignore them
    def to_xml(_opts = {})
      pub = Nokogiri::XML('<publicObject/>').root
      pub['id'] = public_cocina.externalIdentifier
      pub['published'] = Time.now.utc.xmlschema
      pub['publishVersion'] = "cocina-models/#{Cocina::Models::VERSION}"
      pub.add_child(public_identity_metadata.root) # add in modified identityMetadata datastream
      pub.add_child(public_content_metadata.root) if public_content_metadata.xpath('//resource').any?
      pub.add_child(public_rights_metadata)
      pub.add_child(public_relationships.root)
      desc_md_xml = Publish::PublicDescMetadataService.new(public_cocina).ng_xml(include_access_conditions: false)
      pub.add_child(DublinCoreService.new(desc_md_xml).ng_xml.root)
      pub.add_child(PublicDescMetadataService.new(public_cocina).ng_xml.root)
      pub.add_child(release_xml.root) unless release_xml.xpath('//release').children.empty? # If there are no release_tags, this prevents an empty <releaseData/> from being added
      # Note we cannot base this on if an individual object has release tags or not, because the collection may cause one to be generated for an item,
      # so we need to calculate it and then look at the final result.

      thumb = @thumbnail_service.thumb
      pub.add_child(Nokogiri("<thumb>#{thumb}</thumb>").root) unless thumb.nil?
      new_pub = Nokogiri::XML(pub.to_xml, &:noblanks)
      new_pub.encoding = 'UTF-8'
      new_pub.to_xml
    end
    # rubocop:enable Metrics/AbcSize

    private

    attr_reader :released_for, :public_cocina

    # Generate XML structure for inclusion to Purl. This data is read by purl-fetcher.
    # @return [String] The XML release node as a string, with ReleaseDigest as the root document
    def release_xml
      @release_xml ||= begin
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.releaseData do
            released_for.each do |project, released_value|
              xml.release(released_value['release'], to: project)
            end
          end
        end
        Nokogiri::XML(builder.to_xml)
      end
    end

    def public_relationships
      Nokogiri::XML(PublishedRelationshipsFilter.new(public_cocina).xml)
    end

    def public_rights_metadata
      @public_rights_metadata ||= RightsMetadata.new(public_cocina, release_date).create
    end

    def release_date
      return unless public_cocina.dro? && public_cocina.access.embargo

      public_cocina.access.embargo.releaseDate.utc.iso8601
    end

    SYMPHONY = 'symphony'

    # catkeys are used by PURL
    # objectType is used by purl-fetcher
    # objectLabel is used by https://github.com/sul-dlss/searchworks_traject_indexer/blob/b5ed9906a5a0130eca5e68fbb0e8633bdbe6ffd6/lib/sdr_stuff.rb#L54
    def public_identity_metadata
      catkeys = Array(public_cocina.identification&.catalogLinks).filter_map { |link| link.catalogRecordId if link.catalog == SYMPHONY }
      nodes = catkeys.map { |catkey| "  <otherId name=\"catkey\">#{catkey}</otherId>" }
      nodes << "  <otherId name=\"barcode\">#{public_cocina.identification.barcode}</otherId>" if public_cocina.dro? && public_cocina.identification.barcode

      Nokogiri::XML(
        <<~XML
          <identityMetadata>
            <objectType>#{public_cocina.collection? ? 'collection' : 'item'}</objectType>
            <objectLabel>#{Cocina::Models::Builders::TitleBuilder.build(public_cocina.description.title)}</objectLabel>
            <sourceId source="sul">#{public_cocina.identification.sourceId}</sourceId>
            #{nodes.join("\n")}
          </identityMetadata>
        XML
      )
    end

    # @return [Nokogiri::XML::Document] sanitized for public consumption
    def public_content_metadata
      return Nokogiri::XML::Document.new unless public_cocina.dro?

      @public_content_metadata ||= ResourceIdRewriter.call(
        Cocina::ToXml::ContentMetadataGenerator.generate(
          druid: public_cocina.externalIdentifier,
          structural: public_cocina.structural,
          type: public_cocina.type
        )
      )
    end
  end
end
