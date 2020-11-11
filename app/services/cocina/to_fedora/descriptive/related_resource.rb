# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps relatedResource from cocina to MODS relatedItem
      class RelatedResource
        # see https://docs.google.com/spreadsheets/d/1d5PokzgXqNykvQeckG2ND43B6i9_CsjfIVwS_IsphS8/edit#gid=0
        TYPES = {
          'has original version' => 'original',
          'has other format' => 'otherFormat',
          'has part' => 'constituent',
          'has version' => 'otherVersion',
          'in series' => 'series',
          'part of' => 'host',
          'preceded by' => 'preceding',
          'related to' => nil, # 'related to' is a null type by design
          'reviewed by' => 'reviewOf',
          'referenced by' => 'isReferencedBy',
          'references' => 'references',
          'succeeded by' => 'succeeding'
        }.freeze
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] related_resources
        def self.write(xml:, related_resources:)
          new(xml: xml, related_resources: related_resources).write
        end

        def initialize(xml:, related_resources:)
          @xml = xml
          @related_resources = related_resources
        end

        def write
          Array(related_resources).each do |related|
            attributes = {}
            attributes[:type] = TYPES.fetch(related.type) if related.type
            attributes[:displayLabel] = related.displayLabel if related.displayLabel
            xml.relatedItem attributes.compact do
              add_titles(Array(related.title))
              add_location(related.access)
              add_contributors(Array(related.contributor))
              add_physical_description(Array(related.form))
              add_notes(Array(related.note))
            end
          end
        end

        private

        attr_reader :xml, :related_resources

        def add_notes(notes)
          notes.each do |note|
            Note.write_basic(xml, note)
          end
        end

        def add_physical_description(forms)
          forms.each do |form|
            xml.physicalDescription do
              xml.public_send form.type, form.value
            end
          end
        end

        def add_contributors(contributors)
          contributors.each do |contributor|
            attributes = {}
            attributes[:type] = Contributor::NAME_TYPE.fetch(contributor.type) if contributor.type
            xml.name attributes do
              contributor.name.each do |name|
                xml.namePart name.value
              end
            end
          end
        end

        def add_location(access)
          return unless access

          access.url.each do |url|
            xml.location do
              xml.url url.value
            end
          end
        end

        def add_titles(titles)
          titles.each do |title|
            xml.titleInfo do
              xml.title title.value
            end
          end
        end
      end
    end
  end
end
