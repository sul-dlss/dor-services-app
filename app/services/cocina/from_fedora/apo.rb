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
          title_builder = FromFedora::Descriptive::TitleBuilderStrategy.find(label: item.label)
          description = FromFedora::Descriptive.props(title_builder: title_builder, mods: item.descMetadata.ng_xml, druid: item.pid)
          props[:description] = description unless description.nil?
        end
      end

      private

      attr_reader :item

      def build_apo_administrative
        {}.tap do |admin|
          registration_workflows = item.administrativeMetadata.ng_xml.xpath('//administrativeMetadata/registration/workflow/@id').map(&:value)
          dissemination_workflow = item.administrativeMetadata.ng_xml.xpath('//administrativeMetadata/dissemination/workflow/@id').text
          admin[:defaultObjectRights] = item.defaultObjectRights.content
          admin[:disseminationWorkflow] = dissemination_workflow if dissemination_workflow.present?
          admin[:registrationWorkflow] = registration_workflows if registration_workflows.present?
          admin[:hasAdminPolicy] = item.admin_policy_object_id
          admin[:roles] = build_roles
        end
      end

      # @return [Array<Hash>] the list of name and members
      def build_roles
        # rubocop:disable Rails/DynamicFindBy  false positive
        item.roleMetadata.find_by_xpath('/roleMetadata/role').map do |role|
          members = role.xpath('group/identifier').map { |ident| { type: ident['type'], identifier: ident.text } }
          { name: role['type'], members: members }
        end
        # rubocop:enable Rails/DynamicFindBy
      end
    end
  end
end
