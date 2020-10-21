# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps geo extension from cocina to MODS
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

          attributes = {}
          attributes[:authority] = authority
          attributes[:edition] = edition if edition
          attributes[:displayLabel] = display_label if display_label
          xml.classification content, attributes
        end

        private

        attr_reader :xml, :classification

        def content
          subject.first[:value] if subject
        end

        def subject
          classification.first[:subject]
        end

        def authority
          classification.first[:subject].first[:source][:code]
        end

        def display_label
          subject.first[:displayLabel] if subject
        end

        def source
          subject.first[:source] if subject
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
