# frozen_string_literal: true

module Cocina
  module Normalizers
    # Normalizes a Fedora object identity metadata datastream, accounting for differences between Fedora rights and cocina rights that are valid but different
    # when round-tripping.
    class IdentityNormalizer
      include Cocina::Normalizers::Base

      # @param [Nokogiri::Document] identity_ng_xml identity metadata XML to be normalized
      # @param [String] label the object label to add when normalizing
      # @return [Nokogiri::Document] normalized identity metadata xml
      def self.normalize(identity_ng_xml:, label:)
        new(identity_ng_xml: identity_ng_xml, label: label).normalize
      end

      def initialize(identity_ng_xml:, label:)
        @label = label
        @ng_xml = identity_ng_xml.dup
        @ng_xml.encoding = 'UTF-8' if @ng_xml.respond_to?(:encoding=) # sometimes it's a String (?)
      end

      def normalize
        normalize_out_uuid
        normalize_out_admin_tags
        normalize_out_admin_policy
        normalize_out_agreement_id
        normalize_out_set_object_type
        normalize_out_display_type
        normalize_out_object_admin_class
        normalize_out_citation_elements
        normalize_out_call_sequence_ids
        normalize_out_empty_other_ids
        normalize_out_catkeys
        normalize_out_release_tags
        normalize_out_otherid_labels
        normalize_out_apo_hydrus_source_id

        normalize_dissertation_id_to_source_id
        normalize_source_id_whitespace
        normalize_object_creator
        normalize_object_label
        normalize_otherid_dissertationid

        regenerate_ng_xml(ng_xml.to_xml)
      end

      private

      attr_reader :ng_xml

      # for APOs only, remove Hydrus sourceId
      def normalize_out_apo_hydrus_source_id
        return unless ng_xml.root.xpath('//objectType').text == 'adminPolicy'

        ng_xml.root.xpath('//sourceId[@source="Hydrus"]').each(&:remove)
      end

      def normalize_source_id_whitespace
        ng_xml.root.xpath('//sourceId').each do |source_node|
          source_node['source'] = source_node['source']&.strip
          source_node.content = source_node.content&.strip
        end
      end

      # if there is no sourceId, but there is an otherId with name dissertationid, convert the dissertationid to a sourceId
      #   (obviously only applies to (old) ETDs)
      def normalize_dissertation_id_to_source_id
        return if ng_xml.root.xpath('//sourceId').present?

        diss_id_nodes = ng_xml.root.xpath('//otherId[@name="dissertationid"]')
        return if diss_id_nodes.first&.content.blank?

        new_source_id_node = Nokogiri::XML::Node.new('sourceId', ng_xml)
        new_source_id_node.content = diss_id_nodes.first.content
        new_source_id_node['source'] = 'dissertationid'
        diss_id_nodes.first.parent.add_child(new_source_id_node)
        diss_id_nodes.first.remove
      end

      # we don't care about uuids
      def normalize_out_uuid
        ng_xml.root.xpath('//otherId[@name="uuid"]').each(&:remove)
      end

      # administrative tags are stored by the administrative_tag service
      def normalize_out_admin_tags
        ng_xml.root.xpath('//tag').each(&:remove)
      end

      # adminPolicy id is retrieved from RELS-EXT
      def normalize_out_admin_policy
        ng_xml.root.xpath('//adminPolicy').each(&:remove)
      end

      # agreementId is retrieved from RELS-EXT
      def normalize_out_agreement_id
        ng_xml.root.xpath('//agreementId').each(&:remove)
      end

      #  keep objectType collection and drop set (set is vestigial early SDR junk)
      def normalize_out_set_object_type
        ng_xml.root.xpath('//objectType[text() = "set"]').each(&:remove) if ng_xml.root.xpath('//objectType[text() = "collection"]').present?
      end

      # displayType is vestigial early SDR junk
      def normalize_out_display_type
        ng_xml.root.xpath('//displayType').each(&:remove)
      end

      # objectAdminClass is vestigial early SDR junk
      def normalize_out_object_admin_class
        ng_xml.root.xpath('//objectAdminClass').each(&:remove)
      end

      # citationTitle, citationCreator are vestigial early SDR/ETD junk
      def normalize_out_citation_elements
        ng_xml.root.xpath('//citationTitle').each(&:remove)
        ng_xml.root.xpath('//citationCreator').each(&:remove)
      end

      def normalize_out_empty_other_ids
        ng_xml.root.xpath('//otherId').select { |el| el.content.blank? }.each(&:remove)
      end

      # these appear in project phoenix and they are vestigial early SDR junk
      def normalize_out_call_sequence_ids
        ng_xml.root.xpath('//otherId[@name="callseq"]').each(&:remove)
        ng_xml.root.xpath('//otherId[@name="shelfseq"]').each(&:remove)
      end

      def normalize_out_catkeys
        # remove duplicate catkeys
        seen = Set[]
        ng_xml.root.xpath('//otherId[@name="catkey"]').each do |id|
          id.remove if seen.include? id.text
          seen.add id.text
        end

        # remove duplicate previous catkeys
        seen = Set[]
        ng_xml.root.xpath('//otherId[@name="previous_catkey"]').each do |id|
          id.remove if seen.include? id.text
          seen.add id.text
        end
      end

      def normalize_out_otherid_labels
        ng_xml.root.xpath('//otherId[@name="label"]').each(&:remove)
      end

      def normalize_out_release_tags
        ng_xml.root.xpath('//release').each do |release_node|
          release_node.delete('displayType')
          release_node.delete('release')
        end
      end

      # add if missing
      def normalize_object_creator
        return if ng_xml.root.xpath('//objectCreator').present?

        object_creator_node = Nokogiri::XML::Node.new('objectCreator', ng_xml)
        object_creator_node.content = 'DOR'
        ng_xml.root << object_creator_node
      end

      # add objectLabel if none is present
      def normalize_object_label
        return if ng_xml.root.xpath('//objectLabel').present?

        object_label_node = Nokogiri::XML::Node.new('objectLabel', ng_xml)
        object_label_node.content = @label
        ng_xml.root << object_label_node
      end

      def normalize_otherid_dissertationid
        other_id_node = ng_xml.root.xpath('//otherId[@name="dissertationid"]').first
        source_id_node = ng_xml.root.xpath('//sourceId[@source="dissertation"]').first
        return if other_id_node.blank? || source_id_node.blank?

        other_id_node.remove if source_id_node.text == other_id_node.text
      end
    end
  end
end
