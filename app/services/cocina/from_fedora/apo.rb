# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina APO objects from Fedora objects
    class APO
      # @param [Dor::Item,Dor::Etd] item
      # @return [Hash] a hash that can be mapped to a cocina model
      def self.props(item)
        new(item).props
      end

      def initialize(item)
        @item = item
      end

      def props
        {
          externalIdentifier: item.pid,
          type: Cocina::Models::Vocab.admin_policy,
          label: item.label,
          version: item.current_version.to_i,
          administrative: build_apo_administrative
        }.tap do |props|
          description = FromFedora::Descriptive.props(item)
          props[:description] = description unless description.nil?
        end
      end

      private

      attr_reader :item

      def build_apo_administrative
        {}.tap do |admin|
          registration_workflow = item.administrativeMetadata.ng_xml.xpath('//administrativeMetadata/dissemination/workflow/@id').text
          admin[:defaultObjectRights] = item.defaultObjectRights.content
          admin[:registrationWorkflow] = registration_workflow if registration_workflow.present?
          admin[:hasAdminPolicy] = item.admin_policy_object_id if item.admin_policy_object_id
        end
      end
    end
  end
end
