# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps contributors
      class Classification
        NAMESPACE = { 'mods' => DESC_METADATA_NS }.freeze

        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          return unless classification

          [].tap do |data_block|
            data_block << { subject: subject }
          end
        end

        private

        attr_reader :ng_xml

        def classification
          @classification ||= ng_xml.xpath('//mods:mods/mods:classification', NAMESPACE).first
        end

        def subject
          [].tap do |subject_block|
            subject_block << {}.tap do |content|
              content[:type] = 'classification'
              content[:value] = classification.text
              content[:displayLabel] = display_label if display_label
              content[:source] = {}.tap do |source|
                source[:code] = classification.attr('authority')
                source[:version] = format_edition if edition
              end
            end
          end
        end

        def display_label
          classification.attr('displayLabel')
        end

        def edition
          classification.attr('edition')
        end

        def format_edition
          "#{edition.to_i.ordinalize} edition"
        end
      end
    end
  end
end
