# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps classification extension from cocina to MODS
      class Classification
        DEORDINAL_REGEX = /(?<=[0-9])(?:st|nd|rd|th)/.freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] geo
        def self.write(xml:, classification:)
          new(xml: xml, classification: classification).write
        end

        def initialize(xml:, classification:)
          @xml = xml
          @classification = classification
        end

        def write
          return if classification.nil?

          attributes = { authority: authority,
                         edition: edition,
                         displayLabel: display_label }.compact
          xml.classification content, attributes
        end

        private

        attr_reader :xml, :classification

        def content
          first_subject[:value]
        end

        def first_subject
          classification.first[:subject]&.first || {}
        end

        def authority
          first_subject[:source][:code]
        end

        def display_label
          first_subject[:displayLabel]
        end

        def source
          first_subject[:source]
        end

        def edition
          return unless source[:version]

          edition = source[:version].split.first
          edition.gsub(DEORDINAL_REGEX, '')
        end
      end
    end
  end
end
