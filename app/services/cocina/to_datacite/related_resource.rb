# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::Description relatedResource attributes to the DataCite relatedItem attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class RelatedResource
      RELATION_TYPE_MAP = {
        'supplement to' => 'IsSupplementTo',
        'supplemented by' => 'IsSupplementedBy',
        'referenced by' => 'IsReferencedBy',
        'references' => 'References',
        'derived from' => 'IsDerivedFrom',
        'source of' => 'IsSourceOf',
        'version of record' => 'IsVersionOf',
        'identical to' => 'IsIdenticalTo',
        'has version' => 'HasVersion',
        'preceded by' => 'Continues',
        'succeeded by' => 'IsContinuedBy',
        'part of' => 'IsPartOf',
        'has part' => 'HasPart'
      }.freeze

      # @param [Cocina::Models::RelatedResource] related_resource
      # @return [Hash] Hash of DataCite relatedItem attributes, conforming to the expectations of HTTP PUT
      # request to DataCite or nil if blank
      #  see https://support.datacite.org/reference/dois-2#put_dois-id
      def self.related_item_attributes(related_resource)
        new(related_resource).related_item_attributes
      end

      # @param [Cocina::Models::RelatedResource] related_resource
      # @return [Hash] Hash of DataCite relatedIdentifier attributes, conforming to the expectations of HTTP PUT
      # request to DataCite or nil if blank
      #  see https://support.datacite.org/reference/dois-2#put_dois-id
      def self.related_identifier_attributes(related_resource)
        new(related_resource).related_identifier_attributes
      end

      def initialize(related_resource)
        @related_resource = related_resource
      end

      # @return [Hash,nil] Array of DataCite relatedItem attributes, conforming to the expectations of HTTP PUT
      # request to DataCite or nil if blank
      #  see https://support.datacite.org/reference/dois-2#put_dois-id
      def related_item_attributes
        return if related_resource_blank?

        titles = related_item_title ? [title: related_item_title] : []
        id, type = unpack_related_uri_and_type

        if id && type
          {
            relatedItemType: 'Other',
            titles: titles,
            relationType: relation_type,
            relatedItemIdentifier: id,
            relatedItemIdentifierType: type
          }
        else
          {
            relatedItemType: 'Other',
            titles: titles,
            relationType: relation_type
          }
        end
      end

      # @return [Hash,nil] Array of DataCite relatedIdentifier attributes, conforming to the expectations of HTTP PUT
      # request to DataCite or nil if blank or the identifier lacks a URI or Type
      #  see https://support.datacite.org/reference/dois-2#put_dois-id
      def related_identifier_attributes
        return if related_identifier_blank?

        id, type = unpack_related_uri_and_type
        return unless id && type

        {
          resourceTypeGeneral: 'Other',
          relationType: relation_type,
          relatedIdentifier: id,
          relatedIdentifierType: type
        }
      end

      private

      attr_reader :related_resource

      def relation_type
        RELATION_TYPE_MAP.fetch(related_resource.type, 'References')
      end

      def related_resource_blank?
        return true if related_resource.blank?

        related_resource_hash = related_resource.to_h.slice(:note, :title, :access, :identifier)
        related_resource_hash.blank? || related_resource_hash.each_value.all?(&:blank?)
      end

      def related_identifier_blank?
        return true if related_resource.blank?

        related_resource_hash = related_resource.to_h.slice(:access, :identifier)
        related_resource_hash.blank? || related_resource_hash.each_value.all?(&:blank?)
      end

      def related_item_title
        @related_item_title ||= preferred_citation || other_title \
          || related_item_doi || related_item_arxiv || related_item_pmid \
          || related_item_identifier_url
      end

      def preferred_citation
        Array(related_resource.note).find do |note|
          note.type == 'preferred citation' && note.value.present?
        end&.value
      end

      def other_title
        Array(related_resource.title).find do |title|
          title.value.present?
        end&.value
      end

      def related_item_doi
        Array(related_resource.identifier).find do |identifier|
          identifier.type == 'doi' && identifier.uri.present?
        end&.uri
      end

      def related_item_arxiv
        Array(related_resource.identifier).find do |identifier|
          identifier.type == 'arxiv' && identifier.uri.present?
        end&.uri
      end

      def related_item_pmid
        Array(related_resource.identifier).find do |identifier|
          identifier.type == 'pmid' && identifier.uri.present?
        end&.uri
      end

      def related_item_identifier_url
        @related_item_identifier_url ||= Array(related_resource.access&.url).find do |url|
          url.value.present?
        end&.value
      end

      def unpack_related_uri_and_type
        if related_item_doi
          [related_item_doi, 'DOI']
        elsif related_item_arxiv
          [related_item_arxiv, 'arXiv']
        elsif related_item_pmid
          [related_item_pmid, 'PMID']
        elsif related_item_identifier_url
          [related_item_identifier_url, 'URL']
        end
      end
    end
  end
end
