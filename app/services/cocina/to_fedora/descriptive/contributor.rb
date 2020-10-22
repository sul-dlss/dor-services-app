# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps contributors from cocina to MODS XML
      class Contributor
        NAME_TYPE = FromFedora::Descriptive::Contributor::ROLES.invert.freeze
        NAME_PART = FromFedora::Descriptive::Contributor::NAME_PART.invert.freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::Contributor>] contributors
        def self.write(xml:, contributors:)
          new(xml: xml, contributors: contributors).write
        end

        def initialize(xml:, contributors:)
          @xml = xml
          @contributors = contributors
        end

        def write
          Array(contributors).each_with_index do |contributor, _alt_rep_group|
            if contributor.name.count == 1
              write_basic(contributor)
            else
              write_complex(contributor)
            end
          end
        end

        private

        attr_reader :xml, :contributors

        def name_attributes(contributor)
          { type: NAME_TYPE.fetch(contributor.type) }.tap do |attributes|
            attributes[:usage] = 'primary' if contributor.status == 'primary'
          end
        end

        def write_basic(contributor)
          xml.name name_attributes(contributor) do
            xml.namePart contributor.name.first.value
          end
        end

        def write_complex(contributor)
          xml.name name_attributes(contributor) do
            contributor.name.each do |name|
              Array(name.structuredValue).each do |part|
                xml.namePart part.value, type: NAME_PART.fetch(part.type)
              end

              xml.displayForm name.value if name.type == 'display'
            end
            contributor.note.each do |note|
              case note.type
              when 'affiliation'
                xml.affiliation note.value
              when 'description'
                xml.description note.value
              else
                raise "Unknown contributor note type #{note.type}"
              end
            end

            contributor.identifier.each do |ident|
              xml.nameIdentifier ident.value, type: ident.source.code
            end
          end
        end
      end
    end
  end
end
