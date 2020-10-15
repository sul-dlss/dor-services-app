# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps contributors from cocina to MODS XML
      class Contributor
        NAME_TYPE = FromFedora::Descriptive::Contributor::ROLES.invert.freeze

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
            write_basic(contributor)
          end
        end

        private

        attr_reader :xml, :contributors

        def write_basic(contributor)
          attributes = {}
          attributes[:type] = NAME_TYPE.fetch(contributor.type)
          attributes[:usage] = 'primary' if contributor.status == 'primary'
          xml.name attributes do
            xml.namePart contributor.name.first.value
          end
        end
      end
    end
  end
end
