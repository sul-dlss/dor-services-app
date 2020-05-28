# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Administrative objects from Fedora objects
    class Administrative
      # @param [Dor::Item,Dor::Etd] item
      # @return [Hash] a hash that can be mapped to a cocina administrative model
      def self.props(item)
        new(item).props
      end

      def initialize(item)
        @item = item
      end

      def props
        {}.tap do |admin|
          admin[:hasAdminPolicy] = item.admin_policy_object_id if item.admin_policy_object_id
          release_tags = build_release_tags
          admin[:releaseTags] = release_tags unless release_tags.empty?
          projects = AdministrativeTags.project(pid: item.id)
          admin[:partOfProject] = projects.first if projects.any?
        end
      end

      private

      attr_reader :item

      def build_release_tags
        item.identityMetadata.ng_xml.xpath('//release').map do |node|
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
