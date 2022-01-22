# frozen_string_literal: true

module Cocina
  module Normalizers
    # Normalizes a Fedora object embargo metadata datastream
    class EmbargoNormalizer
      include Cocina::Normalizers::Base

      # @param [Nokogiri::Document] embargo_ng_xml embargo metadata XML to be normalized
      # @return [Nokogiri::Document] normalized embargo metadata xml
      def self.normalize(embargo_ng_xml:)
        new(embargo_ng_xml: embargo_ng_xml).normalize
      end

      def initialize(embargo_ng_xml:)
        @ng_xml = embargo_ng_xml.dup
        @ng_xml.encoding = 'UTF-8' if @ng_xml.respond_to?(:encoding=) # sometimes it's a String (?)
      end

      def normalize
        return regenerate_ng_xml(ng_xml.to_xml) if normalize_released?

        normalize_empty

        regenerate_ng_xml(ng_xml.to_xml)
      end

      private

      attr_reader :ng_xml

      def normalize_empty
        ng_xml.root.xpath('*[count(*) = 0]').each(&:remove)
        ng_xml.root.remove if ng_xml.root.xpath('*').empty?
      end

      def normalize_released?
        return false if ng_xml.root.xpath('//status[text() = "released"]').blank?

        ng_xml.root.remove
        true
      end
    end
  end
end
