# frozen_string_literal: true

module Cocina
  # Normalizes a Fedora MODS document, accounting for differences between Fedora MODS and MODS generated from Cocina.
  class ModsNormalizer
    # @param [Nokogiri::Document] mods_ng_xml MODS to be normalized
    # @param [Nokogiri::Document] mods_ng_xml2 MODS to be compared (actual)
    # @return [Nokogiri::Document] normalized MODS
    def self.normalize(mods_ng_xml)
      ModsNormalizer.new(mods_ng_xml).normalize
    end

    def initialize(mods_ng_xml)
      @ng_xml = mods_ng_xml.dup
    end

    def normalize
      normalize_default_namespace
      normalize_version
      normalize_topics
      normalize_subject_name
      normalize_authority_uris
      normalize_origin_info_event_types
      normalize_subject_authority
      normalize_text_role_term
      normalize_role_term_authority
      normalize_purl
      ng_xml
    end

    private

    attr_reader :ng_xml

    def normalize_default_namespace
      xml = ng_xml.to_s

      unless xml.include?('xmlns="http://www.loc.gov/mods/v3"')
        xml.sub!('mods:mods', 'mods:mods xmlns="http://www.loc.gov/mods/v3"')
        xml.gsub!('mods:', '')
      end
      @ng_xml = Nokogiri::XML(xml) { |config| config.default_xml.noblanks }
    end

    def normalize_version
      # Only normalize version when version isn't mapped.
      unless /MODS version (\d\.\d)/.match(ng_xml.root.at('//mods:recordInfo/mods:recordOrigin',
                                                          mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS)&.content)
        ng_xml.root['version'] = '3.6'
        ng_xml.root['xsi:schemaLocation'] = 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd'
      end
    end

    def normalize_topics
      ng_xml.root.xpath('//mods:subject[count(mods:topic) = 1]', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).each do |subject_node|
        topic_node = subject_node.xpath('mods:topic', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).first
        normalize_subject(subject_node, topic_node)
      end
    end

    def normalize_authority_uris
      ng_xml.root.xpath("//mods:*[@authorityURI='http://id.loc.gov/authorities/names']", mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).each do |node|
        node[:authorityURI] = 'http://id.loc.gov/authorities/names/'
      end
      ng_xml.root.xpath("//mods:*[@authorityURI='http://id.loc.gov/authorities/subjects']", mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).each do |node|
        node[:authorityURI] = 'http://id.loc.gov/authorities/subjects/'
      end
      ng_xml.root.xpath("//mods:*[@authorityURI='http://id.loc.gov/vocabulary/relators']", mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).each do |node|
        node[:authorityURI] = 'http://id.loc.gov/vocabulary/relators/'
      end
    end

    def normalize_subject_name
      ng_xml.root.xpath('//mods:subject[count(mods:name) = 1]', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).each do |subject_node|
        name_node = subject_node.xpath('mods:name', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).first
        normalize_subject(subject_node, name_node)
      end
    end

    def normalize_subject(subject_node, child_node)
      return unless subject_node[:authorityURI] || subject_node[:valueURI]

      # If subject has authority and child doesn't, copy to child.
      child_node[:authority] = subject_node[:authority] if subject_node[:authority] && !child_node[:authority]
      # If subject has authorityURI and child doesn't, move to child.
      child_node[:authorityURI] = subject_node[:authorityURI] if subject_node[:authorityURI] && !child_node[:authorityURI]
      subject_node.delete('authorityURI')
      # If subject has valueURI and child doesn't, move to child.
      child_node[:valueURI] = subject_node[:valueURI] if subject_node[:valueURI] && !child_node[:valueURI]
      subject_node.delete('valueURI')
    end

    def normalize_subject_authority
      ng_xml.root.xpath("//mods:subject[@authority='naf']", mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).each do |subject_node|
        subject_node[:authority] = 'lcsh'
      end
    end

    # change original xml to have the event type that will be output
    def normalize_origin_info_event_types
      # code
      ng_xml.root.xpath('mods:originInfo', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).each do |origin_info_node|
        date_issued_nodes = origin_info_node.xpath('mods:dateIssued', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS)
        add_event_type('publication', origin_info_node) && next if date_issued_nodes.present?

        copyright_date_nodes = origin_info_node.xpath('mods:copyrightDate', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS)
        add_event_type('copyright notice', origin_info_node) && next if copyright_date_nodes.present?

        date_created_nodes = origin_info_node.xpath('mods:dateCreated', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS)
        add_event_type('production', origin_info_node) && next if date_created_nodes.present?

        date_captured_nodes = origin_info_node.xpath('mods:dateCaptured', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS)
        add_event_type('capture', origin_info_node) && next if date_captured_nodes.present?
      end
    end

    def add_event_type(value, origin_info_node)
      origin_info_node['eventType'] = value if origin_info_node[:eventType].blank?
    end

    def normalize_text_role_term
      ng_xml.root.xpath("//mods:roleTerm[@type='text']", mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).each do |role_term_node|
        role_term_node.content = role_term_node.content.downcase
      end
    end

    def normalize_role_term_authority
      ng_xml.root.xpath("//mods:roleTerm[@authority='marcrelator']", mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).each do |role_term_node|
        role_term_node['authorityURI'] = 'http://id.loc.gov/vocabulary/relators/'
      end
    end

    def normalize_purl
      ng_xml.root.xpath('//mods:location', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).each do |location_node|
        url_nodes = location_node.xpath('mods:url', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS)
        purl_node = url_nodes.find { |url_node| Cocina::FromFedora::Descriptive::Location::PURL_REGEX.match(url_node.text) }
        has_primary_usage = url_nodes.any? { |url_node| url_node[:usage] == 'primary display' }
        purl_node[:usage] = 'primary display' if purl_node && !has_primary_usage
      end
    end
  end
end
