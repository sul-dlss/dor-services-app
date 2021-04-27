# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina::Administrative object properties from Fedora objects
    class Administrative
      # @param [Dor::Item,Dor::Etd,Dor::Collection] fedora_object
      # @return [Hash] a hash that can be mapped to a Cocina::Administrative object
      def self.props(fedora_object)
        new(fedora_object).props
      end

      def initialize(fedora_object)
        @fedora_object = fedora_object
      end

      def props
        {}.tap do |admin|
          admin[:hasAdminPolicy] = fedora_object.admin_policy_object_id if fedora_object.admin_policy_object_id
          release_tags = build_release_tags
          admin[:releaseTags] = release_tags unless release_tags.empty?
          projects = AdministrativeTags.project(pid: fedora_object.id)
          admin[:partOfProject] = projects.first if projects.any?
        end
      end

      private

      attr_reader :fedora_object

      def build_release_tags
        fedora_object.identityMetadata.ng_xml.xpath('//release').map do |node|
          {
            to: node.attributes['to'].value,
            what: node.attributes['what'].value,
            date: node.attributes['when'].value,
            who: node.attributes['who'].value,
            release: node.text == 'true'
          }
        end
      end
    end
  end
end
