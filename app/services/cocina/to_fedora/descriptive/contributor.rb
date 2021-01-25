# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps contributors from cocina to MODS XML
      class Contributor
        # one way mapping:  MODS 'corporate' already maps to Cocina 'organization'
        NAME_TYPE = Cocina::FromFedora::Descriptive::Contributor::ROLES.invert.merge('event' => 'corporate').freeze
        NAME_PART = FromFedora::Descriptive::Contributor::NAME_PART.invert.freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::Contributor>] contributors
        # @params [Array<Cocina::Models::Title>] titles
        # @params [IdGenerator] id_generator
        def self.write(xml:, contributors:, titles:, id_generator:)
          new(xml: xml, contributors: contributors, titles: titles, id_generator: id_generator).write
        end

        def initialize(xml:, contributors:, titles:, id_generator:)
          @xml = xml
          @contributors = contributors
          @titles = titles
          @id_generator = id_generator
        end

        def write
          Array(contributors)
            .reject { |contributor| NameTitleGroup.part_of_nametitlegroup?(contributor: contributor, titles: titles) }
            .each { |contributor| ContributorWriter.write(xml: xml, contributor: contributor, id_generator: id_generator) }
        end

        private

        attr_reader :xml, :contributors, :titles, :id_generator
      end
    end
  end
end
